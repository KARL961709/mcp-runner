# =============================================================================
# 10 — Proyección RD12 por chain-ladder (Reenganche)
# =============================================================================
# Triángulo de desarrollo: RD a cada horizonte (1m-12m) por cohorte.
# Factor f(h->12m) = mediana(rd_12m / rd_hm) sobre cohortes maduras (excl COVID).
# Cohortes inmaduras (Z2): RD12_proj = rd_hm observado * f(h->12m).
# =============================================================================

import json
import sys
import warnings
from pathlib import Path

import numpy as np
import pandas as pd

warnings.filterwarnings("ignore")

_PROJECT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_PROJECT / 'src'))

from config import (
    RANDOM_SEED, PATHS, MASTER_PARQUET, SUBPRODUCTO_FILTER,
    COHORTE_FIN, RD_HIST_INI, RD_HIST_FIN,
    COVID_EXCL_MONTHS, DRIVER_COLS, MIN_COHORTS_DEV_FACTOR,
    filtro_poblacion,
    PROY_METODO, PROY_VENTANA_INICIO, PROY_DEV_START,
    PROY_SUAVIZAMIENTO, PROY_PERCENTIL_PRUEBA, PROY_CAP_RNG,
    PROY_MAX_MESES_ADELANTE,
)

np.random.seed(RANDOM_SEED)
COVID_SET = set(COVID_EXCL_MONTHS)
DESCARTES_GLOBAL = {}
MIN_COHORTS_FOR_FACTOR = MIN_COHORTS_DEV_FACTOR
CODMES_CIERRE = int(COHORTE_FIN)
CODMES_DATA_FIN = int(RD_HIST_FIN)


def _codmes_diff(c1, c2):
    return (c1 // 100 * 12 + c1 % 100) - (c2 // 100 * 12 + c2 % 100)


def _codmes_add(c, k):
    """Suma k meses a un codmes YYYYMM entero (cruza anio correctamente)."""
    t = c // 100 * 12 + (c % 100 - 1) + k
    return (t // 12) * 100 + (t % 12 + 1)


def compute_maturity_rd(df_subset):
    """RD a cada horizonte (1m-12m) por codmes. Index codmes(int), cols rd_1m..rd_12m, n."""
    df_tmp = df_subset.copy()
    df_tmp['codmes_int'] = df_tmp['codmes'].astype(int)
    rows = []
    for cm, grp in df_tmp.groupby('codmes_int'):
        fila = {'codmes': cm, 'n': len(grp)}
        for h in range(1, 13):
            col = f'target_{h}m'
            if col in grp.columns:
                vals = grp[col].astype(float)
                valid = vals.notna().sum()
                fila[f'rd_{h}m'] = float(vals.sum() / valid) if valid > 0 else np.nan
            else:
                fila[f'rd_{h}m'] = np.nan
        rows.append(fila)
    return pd.DataFrame(rows).set_index('codmes').sort_index()


def compute_dev_factors(df_met, codmes_cierre):
    """Factores de desarrollo mediana f(h->12m) sobre cohortes maduras (excl COVID)."""
    covid_int = [int(m) for m in COVID_SET]
    mature = df_met[df_met.index <= codmes_cierre].copy()
    mature = mature[~mature.index.isin(covid_int)]
    factors, factor_details = {}, {}
    for mat in range(1, 12):
        col_base = f'rd_{mat}m'
        if col_base not in mature.columns:
            continue
        valid = mature[(mature[col_base] > 0) & (mature['rd_12m'] > 0)]
        if len(valid) >= MIN_COHORTS_FOR_FACTOR:
            devs = valid['rd_12m'] / valid[col_base]
            factors[mat] = float(devs.median())
            factor_details[mat] = {
                'median': float(devs.median()),
                'mean': float(devs.mean()),
                'std': float(devs.std()),
                'p25': float(devs.quantile(0.25)),
                'p75': float(devs.quantile(0.75)),
                'n_cohorts': int(len(valid)),
            }
    return factors, factor_details


def percentrank_inc(arr, value):
    """PERCENTRANK.INC de Excel, replicado tal cual del metodo PP_VC/BN."""
    arr = np.asarray(arr, dtype=float)
    if len(arr) == 0:
        return np.nan
    if len(arr) == 1:
        return 1.0
    return float(np.sum(arr < value) / (len(arr) - 1))


def _variantes_v123(df_met, cm, actual_mat, rd_base, base_v3):
    """V1/V2/V3 del metodo PP_VC. Devuelve (dict, nuevo_base_v3).

    hist_rd  : cohortes [VENTANA_INICIO, cm] INCLUSIVE  con rd_{mat}m > 0
    hist_dev : cohortes [VENTANA_INICIO, cm) EXCLUSIVE  con rd_12m > 0 y rd_{mat}m > 0
    Ambos excluyen COVID: BN no lo necesitaba porque su ventana arranca despues,
    la de Reenganche lo atraviesa.
    """
    covid_int = [int(m) for m in COVID_SET]
    col = f'rd_{actual_mat}m'
    ven = (df_met.index >= PROY_VENTANA_INICIO) & (~df_met.index.isin(covid_int))

    hr = df_met.loc[ven & (df_met.index <= cm), col].dropna()
    hist_rd = hr[hr > 0].values

    sub = df_met.loc[ven & (df_met.index < cm)]
    msk = (sub['rd_12m'] > 0) & (sub[col] > 0)
    hist_dev = (sub.loc[msk, 'rd_12m'] / sub.loc[msk, col]).values

    if len(hist_rd) == 0 or len(hist_dev) == 0:
        return None, base_v3

    rng_p = min(percentrank_inc(hist_rd, rd_base), PROY_CAP_RNG)
    q = PROY_SUAVIZAMIENTO * (1 - rng_p) + (1 - PROY_SUAVIZAMIENTO) * rng_p
    fact_autom = float(np.percentile(hist_dev, q * 100))
    fact_prueba = float(np.percentile(hist_dev, PROY_PERCENTIL_PRUEBA * 100))

    v1 = rd_base * fact_autom
    v2 = rd_base * ((fact_autom + fact_prueba) / 2)

    var_rdx = 0.0
    cm_ant = _codmes_add(cm, -1)
    if cm_ant in df_met.index and col in df_met.columns:
        prev = df_met.loc[cm_ant, col]
        if not pd.isna(prev) and prev > 0:
            var_rdx = (rd_base / prev) - 1
    v3_mom = base_v3 * (1 + var_rdx) if not pd.isna(base_v3) else np.nan
    v3 = (v2 + v3_mom) / 2 if not pd.isna(v3_mom) else np.nan

    d = dict(rng_p=float(rng_p), fact_autom=fact_autom, fact_prueba=fact_prueba,
             n_hist_rd=int(len(hist_rd)), n_hist_dev=int(len(hist_dev)),
             rd12_proj_v1=float(v1), rd12_proj_v2=float(v2),
             rd12_proj_v3_mom=float(v3_mom) if not pd.isna(v3_mom) else None,
             rd12_proj_v3=float(v3) if not pd.isna(v3) else None)
    return d, (v3_mom if not pd.isna(v3_mom) else base_v3)


def compute_projections(df_met, dev_factors, codmes_cierre, codmes_data_fin,
                        label='GLOBAL'):
    """Proyecta RD12 para meses posteriores al cierre.

    Emite las CUATRO variantes (mediana + V1/V2/V3 del metodo PP_VC) y expone en
    `rd12_proj` la que selecciona PROY_METODO, que es la que consume el Excel.
    Los descartes se CUENTAN y se reportan: antes se caian por un `continue`
    silencioso y la cobertura de la proyeccion no era visible en ningun lado.
    """
    projections = []
    descartes = {'sin_madurez': [], 'rd_base_cero': [], 'sin_factor': [],
                 'bajo_dev_start': [], 'fuera_horizonte': []}
    base_v3 = np.nan
    if codmes_cierre in df_met.index and not pd.isna(df_met.loc[codmes_cierre, 'rd_12m']):
        base_v3 = float(df_met.loc[codmes_cierre, 'rd_12m'])
    for cm in sorted(df_met.index):
        if cm <= codmes_cierre:
            continue
        # Tope de horizonte: meses hacia adelante desde el cierre.
        if _codmes_diff(cm, codmes_cierre) > PROY_MAX_MESES_ADELANTE:
            descartes['fuera_horizonte'].append(str(cm))
            continue
        actual_mat = _codmes_diff(codmes_data_fin, cm) + 1
        if actual_mat < 1:
            descartes['sin_madurez'].append(str(cm))
            continue
        actual_mat = min(actual_mat, 11)
        col_base = f'rd_{actual_mat}m'
        if col_base not in df_met.columns:
            continue
        rd_base = df_met.loc[cm, col_base]
        if pd.isna(rd_base) or rd_base <= 0:
            if actual_mat >= 3:
                for fallback in range(actual_mat - 1, 0, -1):
                    fb_col = f'rd_{fallback}m'
                    if fb_col in df_met.columns:
                        rd_fb = df_met.loc[cm, fb_col]
                        if not pd.isna(rd_fb) and rd_fb > 0 and fallback in dev_factors:
                            rd_base = rd_fb
                            actual_mat = fallback
                            col_base = fb_col
                            break
            if pd.isna(rd_base) or rd_base <= 0:
                descartes['rd_base_cero'].append(str(cm))
                continue
        if actual_mat not in dev_factors:
            descartes['sin_factor'].append(str(cm))
            continue
        if actual_mat < PROY_DEV_START:
            descartes['bajo_dev_start'].append(str(cm))
            continue
        rd_med = float(rd_base * dev_factors[actual_mat])
        fila = {
            'codmes': str(cm),
            'maturity_months': actual_mat,
            'rd_base': float(rd_base),
            'dev_factor': float(dev_factors[actual_mat]),
            'rd12_proj_mediana': rd_med,
            'n': int(df_met.loc[cm, 'n']),
        }
        var, base_v3 = _variantes_v123(df_met, cm, actual_mat, rd_base, base_v3)
        if var:
            fila.update(var)
        # `rd12_proj` es lo que consume el Excel: apunta al metodo seleccionado.
        sel = {'mediana': 'rd12_proj_mediana', 'v1': 'rd12_proj_v1',
               'v2': 'rd12_proj_v2', 'v3': 'rd12_proj_v3'}[PROY_METODO]
        val = fila.get(sel)
        fila['metodo'] = PROY_METODO
        fila['rd12_proj'] = float(val) if val is not None and not pd.isna(val) else rd_med
        if val is None or pd.isna(val):
            fila['metodo'] = f'{PROY_METODO}->mediana (sin historia suficiente)'
        projections.append(fila)
    n_desc = sum(len(v) for v in descartes.values())
    if label == 'GLOBAL':
        DESCARTES_GLOBAL.update({k: v for k, v in descartes.items() if v})
    if n_desc:
        det = "  ".join(f"{k}={len(v)}" for k, v in descartes.items() if v)
        print(f"   [{label}] cohortes sin proyeccion: {n_desc} ({det})")
    return projections


df_master = pd.read_parquet(MASTER_PARQUET)
df_master['codmes'] = df_master['codmes'].astype(str)
# Mismo recorte de poblacion que 00_load_data: el chain-ladder tiene que
# proyectar sobre la MISMA poblacion que se calibro, o los factores de
# desarrollo salen de un universo y se aplican a otro.
# El tope es RD_HIST_FIN (frontera de DATO), no COHORTE_FIN: el metodo
# necesita justamente las cohortes inmaduras.
df_all = df_master[
    filtro_poblacion(df_master) &
    (df_master['codmes'] >= RD_HIST_INI) &
    (df_master['codmes'] <= RD_HIST_FIN) &
    (df_master['target_1m'].notna())
].copy()

df_met = compute_maturity_rd(df_all)
factors, factor_details = compute_dev_factors(df_met, CODMES_CIERRE)
projections = compute_projections(df_met, factors, CODMES_CIERRE, CODMES_DATA_FIN, 'GLOBAL')

rd12_projs = [p['rd12_proj'] for p in projections]
print(f"10 Chain-ladder {SUBPRODUCTO_FILTER} | cohortes={len(df_met)} | factores={len(factors)} | "
      f"proyecciones={len(projections)}" +
      (f" | RD12_proj media={np.mean(rd12_projs)*100:.3f}%" if rd12_projs else ""))

# Proyecciones por driver
by_driver = {}
for drv in [d for d in DRIVER_COLS if d in df_all.columns]:
    df_drv = df_all[df_all[drv].notna()].copy()
    driver_result = {}
    for val in sorted(df_drv[drv].unique(), key=str):
        v = str(val)
        sub = df_drv[df_drv[drv].astype(str) == v]
        if len(sub) == 0:
            continue
        df_met_drv = compute_maturity_rd(sub)
        factors_drv, details_drv = compute_dev_factors(df_met_drv, CODMES_CIERRE)
        proj_drv = compute_projections(df_met_drv, factors_drv, CODMES_CIERRE, CODMES_DATA_FIN, f'{drv}={v}')
        driver_result[v] = {
            'n_obs': len(sub),
            'dev_factors': {str(k): fv for k, fv in factors_drv.items()},
            'dev_factor_details': {str(k): fv for k, fv in details_drv.items()},
            'projections': proj_drv,
        }
    by_driver[drv] = driver_result

output = {
    'product': SUBPRODUCTO_FILTER,
    'codmes_cierre': COHORTE_FIN,
    'data_fin': RD_HIST_FIN,
    'min_cohorts_for_factor': MIN_COHORTS_FOR_FACTOR,
    'metodo': PROY_METODO,
    'proy_ventana_inicio': PROY_VENTANA_INICIO,
    'proy_dev_start': PROY_DEV_START,
    'proy_max_meses_adelante': PROY_MAX_MESES_ADELANTE,
    'proy_suavizamiento': PROY_SUAVIZAMIENTO,
    'proy_percentil_prueba': PROY_PERCENTIL_PRUEBA,
    'proy_cap_rng': PROY_CAP_RNG,
    'n_sin_proyeccion': sum(len(v) for v in DESCARTES_GLOBAL.values()),
    'cohortes_sin_proyeccion': DESCARTES_GLOBAL,
    'global': {
        'dev_factors': {str(k): v for k, v in factors.items()},
        'dev_factor_details': {str(k): v for k, v in factor_details.items()},
        'projections': projections,
    },
    'by_driver': by_driver,
}
with open(PATHS['json'] / 'rd_projections.json', 'w') as f:
    json.dump(output, f, indent=2, default=str)

csv_rows = []
for p in projections:
    csv_rows.append({'segment': 'GLOBAL', 'driver': '', 'value': '', **p})
for drv, drv_data in by_driver.items():
    for val, val_data in drv_data.items():
        for p in val_data['projections']:
            csv_rows.append({'segment': f'{drv}={val}', 'driver': drv, 'value': val, **p})
pd.DataFrame(csv_rows).to_csv(PATHS['csv'] / 'rd_projections.csv', index=False)
print(f"  export: rd_projections.json, rd_projections.csv ({len(csv_rows)} filas)")
