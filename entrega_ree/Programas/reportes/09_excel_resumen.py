# =============================================================================
# 09 — Excel resumen TRIMESTRAL por driver (Reenganche)
# =============================================================================
# Hojas: COEFICIENTES, GLOBAL, tipo_ingreso_dep, tipo_ingreso_cs.
# Columnas: trimestre, N, defaults, RD=sum(def)/N, PDs (weighted mean),
#           rd_pred_macro, EC/Jeffreys/Status por cada PD.
# RD trimestral: sum(defaults)/sum(N), NO promedio de RDs mensuales.
# Nota en celda alejada si trimestre incompleto (< 3 meses).
# EC convention: EC = (PD/RD - 1) × 100 (pp, positivo = sobreestimación).
#   Distinta de monitoring.py que usa EC = (RD-PD)/PD (ratio, positivo = subestimación).
#   Ambas son válidas; aquí se usa la convention de Excel/reporting.
# =============================================================================

import json
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import norm

warnings.filterwarnings("ignore")

import sys

_PROJECT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_PROJECT / 'src'))

from config import (
    RANDOM_SEED, PATHS, TARGET_COL, SCORE_COL, SUBPRODUCTO_FILTER,
    SEG_COL, DRIVER_COLS, COHORTE_FIN, COVID_EXCL_MONTHS,
    MACRO_CHAMPION_VARS, SCORE_INI, RD_HIST_FIN,
)
from monitoring import ec_relativo, ec_status, jeffreys_pass

np.random.seed(RANDOM_SEED)

# Destino del xlsx. Por defecto el mismo outdir que el resto (PATHS resuelve
# REE_OUTDIR); REE_REPORTES_DIR lo manda a una carpeta aparte, que es como viaja
# en la entrega: el Excel es un ENTREGABLE y vive separado de los intermedios.
import os as _os
OUTPUT_DIR = (Path(_os.environ['REE_REPORTES_DIR']) if _os.environ.get('REE_REPORTES_DIR')
              else PATHS['json'].parent)
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

MESES_RANGE = [f"{y}{m:02d}" for y in range(2019, 2027) for m in range(1, 13)]
MESES_RANGE = [m for m in MESES_RANGE if SCORE_INI <= m <= RD_HIST_FIN]

PD_SERIES = ['pd', 'pd_ttc_adj', 'pd_pit', 'pd_pit_floor']


def codmes_to_quarter(cm):
    y = cm[:4]
    m = int(cm[4:6])
    q = (m - 1) // 3 + 1
    return f"{y}Q{q}"


def quarter_months(q_label):
    y = int(q_label[:4])
    q = int(q_label[-1])
    return [f"{y}{m:02d}" for m in range((q - 1) * 3 + 1, q * 3 + 1)]

# =============================================================================
# 1. Carga
# =============================================================================

print("=" * 60)
print(f"  09 — EXCEL RESUMEN TRIMESTRAL {SUBPRODUCTO_FILTER}")
print("=" * 60)

df = pd.read_parquet(PATHS['parquets'] / 'full_calibrated.parquet')
df['codmes'] = df['codmes'].astype(str)
df = df[df['codmes'].isin(MESES_RANGE)].copy()
df['quarter'] = df['codmes'].apply(codmes_to_quarter)
print(f"Loaded: {len(df):,} obs, {df['codmes'].nunique()} meses, {df['quarter'].nunique()} trimestres")

with open(PATHS['json'] / 'pit_transformation.json') as f:
    pit_params = json.load(f)
with open(PATHS['json'] / 'vasicek_rho.json') as f:
    rho_params = json.load(f)
with open(PATHS['json'] / 'macro_model.json') as f:
    macro_params = json.load(f)
with open(PATHS['json'] / 'lra.json') as f:
    lra_params = json.load(f)
with open(PATHS['json'] / 'calibracion_beta.json') as f:
    cal_params = json.load(f)

lambda_params = {}
lambda_path = PATHS['json'] / 'lambda_mle_binomial.json'
if lambda_path.exists():
    with open(lambda_path) as f:
        lambda_params = json.load(f)

proj_params = {}
proj_path = PATHS['json'] / 'rd_projections.json'
if proj_path.exists():
    with open(proj_path) as f:
        proj_params = json.load(f)

proj_dict_global = {}
if proj_params:
    for p in proj_params.get('global', {}).get('projections', []):
        proj_dict_global[p['codmes']] = p

# Proyeccion por celda de driver. 10_rd_projections estima los factores de
# desarrollo sobre el triangulo de CADA celda, no prorratea el global: una celda
# con maduracion mas lenta arrastra su propio factor.
proj_dict_driver = {}
if proj_params:
    for _eje, _celdas in proj_params.get('by_driver', {}).items():
        for _v, _d in _celdas.items():
            for p in _d.get('projections', []):
                proj_dict_driver[(_eje, str(_v), p['codmes'])] = p

PROY_VARIANTES = [('RD12_proj', 'rd12_proj'),
                  ('RD_PROY', 'rd12_proj_mediana'),
                  ('RD_PROY_V1', 'rd12_proj_v1'),
                  ('RD_PROY_V2', 'rd12_proj_v2'),
                  ('RD_PROY_V3_MOM', 'rd12_proj_v3_mom'),
                  ('RD_PROY_V3', 'rd12_proj_v3')]

NOTAS_DRIVER = [
    'RD observada (RD_12m..RD_3m): las celdas SI recomponen el GLOBAL ponderando '
    'por N — es una particion, la diferencia medida es 0,0000 pp.',
    'RD proyectada (RD12_proj y RD_PROY*): NO recompone el GLOBAL. Cada celda estima '
    'su propio factor de desarrollo sobre su propio triangulo, y el cuantil adaptativo '
    'de V1 no es lineal. La diferencia medida llega a 0,44 pp. Es una vista POR CELDA, '
    'no una descomposicion del GLOBAL: no se deben sumar.',
]

ft_cal = pd.read_csv(PATHS['csv'] / 'ft_calendario.csv')
ft_cal['codmes'] = ft_cal['codmes'].astype(str)
ft_cal['rd_pred_macro'] = norm.cdf(ft_cal['ft_GLOBAL'].values)
ft_dict = dict(zip(ft_cal['codmes'], ft_cal['rd_pred_macro']))

if 'pd_pit' in df.columns and 'pd_ttc_adj' in df.columns:
    df['pd_pit_floor'] = np.maximum(df['pd_pit'], df['pd_ttc_adj'])

QUARTERS = sorted(df['quarter'].unique())

# =============================================================================
# 2. EC / Jeffreys / Status  (estandar unico en src/monitoring.py:
#    bandas EC x2 Low Default + downgrade por test de Jeffreys bilateral p>5%)
# =============================================================================


def add_ec_columns(row, rd, n_target, defaults, pd_val, suffix):
    if np.isnan(rd) or rd <= 0 or np.isnan(pd_val):
        row[f'EC_{suffix}'] = np.nan
        row[f'J_{suffix}'] = ''
        row[f'ST_{suffix}'] = ''
        return
    ec = ec_relativo(rd, pd_val)              # (RD-PD)/PD ; EC>0 = subestimacion
    row[f'EC_{suffix}'] = ec
    j_pass = jeffreys_pass(defaults, n_target, pd_val)
    row[f'J_{suffix}'] = 'PASS' if j_pass else ('FAIL' if j_pass is not None else '')
    st = ec_status(ec, bool(j_pass) if j_pass is not None else False)
    row[f'ST_{suffix}'] = st.upper() if st != 'nan' else ''


# =============================================================================
# 3. Sheet builders (TRIMESTRAL)
# =============================================================================


def _quarter_n_months(df_sub, q):
    q_months = quarter_months(q)
    available = [m for m in q_months if m in df_sub['codmes'].unique()]
    return len(available)


def build_global_sheet(df_):
    rows = []
    incomplete_quarters = []

    for q in QUARTERS:
        sub = df_[df_['quarter'] == q]
        n = len(sub)
        if n == 0:
            continue

        n_months = _quarter_n_months(df_, q)
        row = {'trimestre': q, 'N': n, 'n_meses': n_months}

        for s in PD_SERIES:
            if s in sub.columns:
                row[s] = sub[s].mean()

        max_codmes_q = sub['codmes'].max()
        is_z1 = max_codmes_q <= COHORTE_FIN
        has_target = TARGET_COL in sub.columns

        if is_z1 and has_target:
            valid = sub[sub[TARGET_COL].notna()]
            total_def = int(valid[TARGET_COL].sum())
            total_n = len(valid)
            row['defaults'] = total_def
            row['N_target'] = total_n
            row['RD'] = total_def / total_n if total_n > 0 else np.nan
        else:
            row['defaults'] = np.nan
            row['N_target'] = np.nan
            row['RD'] = np.nan
            q_months_list = quarter_months(q)
            # Las CINCO variantes del metodo PP_VC, ponderadas por n dentro del
            # trimestre. RD12_proj sigue siendo la seleccionada por PROY_METODO;
            # las demas viajan al lado para poder contrastarlas (mismos nombres
            # que el Excel de Comportamental BN).
            for _dst, _src in [('RD12_proj', 'rd12_proj'),
                               ('RD_PROY', 'rd12_proj_mediana'),
                               ('RD_PROY_V1', 'rd12_proj_v1'),
                               ('RD_PROY_V2', 'rd12_proj_v2'),
                               ('RD_PROY_V3_MOM', 'rd12_proj_v3_mom'),
                               ('RD_PROY_V3', 'rd12_proj_v3')]:
                _num, _den = 0.0, 0
                for cm in q_months_list:
                    _p = proj_dict_global.get(cm)
                    if _p and _p.get(_src) is not None:
                        _num += _p[_src] * _p['n']
                        _den += _p['n']
                if _den > 0:
                    row[_dst] = _num / _den

        # RD observada a cada horizonte 12m..3m. Se calcula por horizonte y NO
        # bajo `is_z1`: un periodo puede tener rd_3m cerrado y rd_12m todavia no,
        # porque cada horizonte madura un mes mas tarde que el siguiente. Es el
        # triangulo de desarrollo sobre el que se apoya la proyeccion.
        for _h in range(12, 2, -1):
            _c = f'target_{_h}m'
            if _c in sub.columns:
                _v = sub[_c].dropna()
                row[f'RD_{_h}m'] = float(_v.sum() / len(_v)) if len(_v) > 0 else np.nan
            else:
                row[f'RD_{_h}m'] = np.nan
        ft_vals = [ft_dict[m] for m in quarter_months(q) if m in ft_dict]
        row['rd_pred_macro'] = np.mean(ft_vals) if ft_vals else np.nan

        rd_val = row.get('RD', np.nan)
        n_tgt = row.get('N_target', 0)
        dflts = row.get('defaults', np.nan)
        for s in PD_SERIES:
            if s in row and not (isinstance(row[s], float) and np.isnan(row[s])):
                add_ec_columns(row, rd_val, n_tgt, dflts, row[s], s)
            else:
                row[f'EC_{s}'] = np.nan
                row[f'J_{s}'] = ''
                row[f'ST_{s}'] = ''

        if n_months < 3:
            incomplete_quarters.append(q)

        rows.append(row)

    result = pd.DataFrame(rows)
    pd_block = []
    for s in PD_SERIES:
        pd_block += [s, f'EC_{s}', f'J_{s}', f'ST_{s}']
    col_order = ['trimestre', 'N', 'n_meses', 'N_target', 'defaults', 'RD']
    col_order += [f'RD_{h}m' for h in range(12, 2, -1)]
    if 'RD12_proj' in result.columns:
        col_order += ['RD12_proj']
    col_order += ['RD_PROY', 'RD_PROY_V1', 'RD_PROY_V2', 'RD_PROY_V3_MOM', 'RD_PROY_V3']
    col_order += pd_block + ['rd_pred_macro']
    col_order = [c for c in col_order if c in result.columns]
    return result[col_order], incomplete_quarters


def build_driver_sheet(df_, driver):
    if driver not in df_.columns:
        return pd.DataFrame(), []

    df_drv = df_[df_[driver].notna()].copy()
    values = sorted(df_drv[driver].unique(), key=str)
    incomplete_quarters = []

    rows = []
    for q in QUARTERS:
        sub_q = df_drv[df_drv['quarter'] == q]
        if len(sub_q) == 0:
            continue

        n_months = _quarter_n_months(df_drv, q)
        row = {'trimestre': q, 'n_meses': n_months}

        for val in values:
            v = str(val)
            mask_val = sub_q[driver].astype(str) == v
            sub_val = sub_q[mask_val]
            n = len(sub_val)

            row[f'N_{v}'] = n

            for s in PD_SERIES:
                if s in sub_val.columns and n > 0:
                    row[f'{s}_{v}'] = sub_val[s].mean()
                else:
                    row[f'{s}_{v}'] = np.nan

            max_codmes_q = sub_q['codmes'].max()
            is_z1 = max_codmes_q <= COHORTE_FIN

            if is_z1 and TARGET_COL in sub_val.columns and n > 0:
                valid = sub_val[sub_val[TARGET_COL].notna()]
                total_def = int(valid[TARGET_COL].sum()) if len(valid) > 0 else 0
                total_n = len(valid)
                row[f'defaults_{v}'] = total_def
                row[f'RD_{v}'] = total_def / total_n if total_n > 0 else np.nan
            else:
                total_n = 0
                row[f'defaults_{v}'] = np.nan
                row[f'RD_{v}'] = np.nan
                # Las cinco variantes de la celda, ponderadas por el n de cada mes
                # dentro del trimestre — mismo criterio que el GLOBAL.
                for _dst, _src in PROY_VARIANTES:
                    _num, _den = 0.0, 0
                    for cm in quarter_months(q):
                        _p = proj_dict_driver.get((driver, v, cm))
                        if _p and _p.get(_src) is not None:
                            _num += _p[_src] * _p['n']
                            _den += _p['n']
                    if _den > 0:
                        row[f'{_dst}_{v}'] = _num / _den

            # RD observada a cada horizonte 12m..3m, fuera de `is_z1` por lo mismo
            # que en GLOBAL: cada horizonte cierra un mes antes que el siguiente.
            for _h in range(12, 2, -1):
                _c = f'target_{_h}m'
                if _c in sub_val.columns and n > 0:
                    _s = sub_val[_c].dropna()
                    row[f'RD_{_h}m_{v}'] = float(_s.sum() / len(_s)) if len(_s) > 0 else np.nan
                else:
                    row[f'RD_{_h}m_{v}'] = np.nan

            rd_drv = row.get(f'RD_{v}', np.nan)
            n_drv = total_n          # el denominador de Jeffreys es el N con target
            d_drv = row.get(f'defaults_{v}', np.nan)
            for s in PD_SERIES:
                col_s = f'{s}_{v}'
                if col_s in row and not (isinstance(row[col_s], float) and np.isnan(row[col_s])):
                    add_ec_columns(row, rd_drv, n_drv, d_drv, row[col_s], f'{s}_{v}')
                else:
                    row[f'EC_{s}_{v}'] = np.nan
                    row[f'J_{s}_{v}'] = ''
                    row[f'ST_{s}_{v}'] = ''

        ft_vals = [ft_dict[m] for m in quarter_months(q) if m in ft_dict]
        row['rd_pred_macro'] = np.mean(ft_vals) if ft_vals else np.nan

        if n_months < 3:
            incomplete_quarters.append(q)

        rows.append(row)

    result = pd.DataFrame(rows)
    col_order = ['trimestre', 'n_meses']
    for val in values:
        v = str(val)
        pd_drv_block = []
        for s in PD_SERIES:
            pd_drv_block += [f'{s}_{v}', f'EC_{s}_{v}', f'J_{s}_{v}', f'ST_{s}_{v}']
        col_order += [f'N_{v}', f'defaults_{v}', f'RD_{v}']
        col_order += [f'RD_{h}m_{v}' for h in range(12, 2, -1)]
        col_order += [f'{d}_{v}' for d, _ in PROY_VARIANTES]
        col_order += pd_drv_block
    col_order += ['rd_pred_macro']
    col_order = [c for c in col_order if c in result.columns]
    return result[col_order], incomplete_quarters


# =============================================================================
# 4. Formatting
# =============================================================================


def format_sheet(ws, df_, writer, incomplete_quarters=None, notas_extra=None):
    workbook = writer.book
    fmt_pct = workbook.add_format({'num_format': '0.00%', 'align': 'center'})
    fmt_ec = workbook.add_format({'num_format': '+0.0%;-0.0%', 'align': 'center'})
    fmt_int = workbook.add_format({'num_format': '#,##0', 'align': 'center'})
    fmt_text = workbook.add_format({'align': 'center'})
    fmt_header = workbook.add_format({
        'bold': True, 'align': 'center', 'bg_color': '#002060',
        'font_color': 'white', 'border': 1,
    })
    fmt_verde = workbook.add_format({
        'align': 'center', 'bg_color': '#C6EFCE', 'font_color': '#006100', 'bold': True})
    fmt_amarillo = workbook.add_format({
        'align': 'center', 'bg_color': '#FFEB9C', 'font_color': '#9C6500', 'bold': True})
    fmt_rojo = workbook.add_format({
        'align': 'center', 'bg_color': '#FFC7CE', 'font_color': '#9C0006', 'bold': True})
    fmt_note = workbook.add_format({
        'italic': True, 'font_color': '#666666', 'font_size': 9, 'text_wrap': True})

    for col_idx, col_name in enumerate(df_.columns):
        ws.set_column(col_idx, col_idx, 14)
        if col_name == 'trimestre':
            ws.set_column(col_idx, col_idx, 10, fmt_text)
        elif col_name.startswith('N') or col_name.startswith('defaults') or col_name == 'n_meses':
            ws.set_column(col_idx, col_idx, 12, fmt_int)
        elif col_name.startswith('EC_'):
            ws.set_column(col_idx, col_idx, 10, fmt_ec)
        elif col_name.startswith(('J_', 'ST_')):
            ws.set_column(col_idx, col_idx, 10, fmt_text)
        elif col_name.startswith(('RD', 'rd_', 'pd_')):
            ws.set_column(col_idx, col_idx, 12, fmt_pct)
        elif col_name.startswith('rd_pred_macro'):
            ws.set_column(col_idx, col_idx, 12, fmt_pct)

    for col_idx, col_name in enumerate(df_.columns):
        ws.write(0, col_idx, col_name, fmt_header)

    for col_idx, col_name in enumerate(df_.columns):
        if col_name.startswith('ST_'):
            for row_idx in range(len(df_)):
                val = df_.iloc[row_idx, col_idx]
                excel_row = row_idx + 1
                if val == 'VERDE':
                    ws.write(excel_row, col_idx, val, fmt_verde)
                elif val == 'AMARILLO':
                    ws.write(excel_row, col_idx, val, fmt_amarillo)
                elif val == 'ROJO':
                    ws.write(excel_row, col_idx, val, fmt_rojo)
                else:
                    ws.write(excel_row, col_idx, val or '', fmt_text)

    notas = []
    for q in (incomplete_quarters or []):
        avail = [m for m in quarter_months(q) if m in MESES_RANGE]
        notas.append(f"{q}: trimestre incompleto ({len(avail)}/3 meses: {', '.join(avail)})")
    notas += list(notas_extra or [])

    if notas:
        note_col = len(df_.columns) + 2
        ws.set_column(note_col, note_col, 40)
        ws.write(0, note_col, 'NOTAS', fmt_header)
        for i, txt in enumerate(notas):
            ws.write(i + 1, note_col, txt, fmt_note)


# =============================================================================
# 5. Generate Excel
# =============================================================================

xlsx_path = OUTPUT_DIR / f'resumen_trimestral_{SUBPRODUCTO_FILTER}.xlsx'

with pd.ExcelWriter(xlsx_path, engine='xlsxwriter') as writer:
    workbook = writer.book

    # ── COEFICIENTES sheet ──
    ws_coef = workbook.add_worksheet('COEFICIENTES')

    fmt_title = workbook.add_format({
        'bold': True, 'font_size': 14, 'align': 'left',
        'bg_color': '#002060', 'font_color': 'white',
    })
    fmt_section = workbook.add_format({
        'bold': True, 'font_size': 11, 'bg_color': '#D9E2F3',
    })
    fmt_key = workbook.add_format({'bold': True, 'align': 'left'})
    fmt_val = workbook.add_format({'align': 'left', 'num_format': '0.000000'})
    fmt_pct_coef = workbook.add_format({'align': 'left', 'num_format': '0.00%'})
    fmt_text_coef = workbook.add_format({'align': 'left'})

    ws_coef.set_column(0, 0, 40)
    ws_coef.set_column(1, 1, 25)

    row = 0
    ws_coef.merge_range(row, 0, row, 1, f'Coeficientes PIT — {SUBPRODUCTO_FILTER}', fmt_title)
    row += 2

    ws_coef.merge_range(row, 0, row, 1, 'PARAMETROS VASICEK', fmt_section)
    row += 1
    vasicek_items = [
        ('rho global (MoM)', pit_params.get('rho_global', '')),
        ('rho method', pit_params.get('rho_method', '')),
        ('rho Basel ref (PD_global)', pit_params.get('rho_basel_ref', '')),
        ('rho_i range [min, max]', str(pit_params.get('rho_range', ''))),
        ('PIT method', pit_params.get('pit_method', '')),
        ('lambda (partial adjustment)', pit_params.get('lambda_pit', '')),
        ('rho_eff = rho * lambda^2',
         pit_params.get('rho_global', 0) * pit_params.get('lambda_pit', 0) ** 2),
        ('ft source', pit_params.get('ft_source', '')),
        ('LRA global', lra_params.get('lra_global', '')),
    ]
    for k, v in vasicek_items:
        ws_coef.write(row, 0, k, fmt_key)
        if isinstance(v, float):
            ws_coef.write(row, 1, v, fmt_val)
        else:
            ws_coef.write(row, 1, str(v), fmt_text_coef)
        row += 1

    # La columna RD12_proj de las hojas de datos sale de aqui: sin esta seccion
    # el Excel publicaba proyecciones sin decir con que metodo se calcularon.
    row += 1
    ws_coef.merge_range(row, 0, row, 1, 'PROYECCION RD12', fmt_section)
    row += 1
    _g = proj_params.get('global', {}) if proj_params else {}
    _pr = _g.get('projections', [])
    _met = _pr[0].get('metodo', 'mediana') if _pr else 'n/d'
    proj_items = [
        ('metodo (alimenta RD12_proj)', _met),
        ('  v1 = RD_mat x percentil(hist_dev, (1-rng_p)x100)', 'cuantil adaptativo PP_VC'),
        ('  rng_p = percentrank_inc(hist_rd, RD_mat)', 'cap 1.0'),
        ('  mediana = RD_mat x mediana(RD12/RD_mat)', 'chain-ladder clasico'),
        ('ventana_inicio cohortes', proj_params.get('proy_ventana_inicio', '')),
        ('madurez minima (dev_start)', proj_params.get('proy_dev_start', '')),
        ('min cohortes por factor', _g.get('min_cohorts_for_factor',
                                           proj_params.get('min_cohorts_for_factor', ''))),
        ('codmes cierre (ultimo RD12 cerrado)', proj_params.get('codmes_cierre', '')),
        ('codmes fin de dato', proj_params.get('data_fin', '')),
        ('cohortes proyectadas', len(_pr)),
        ('cohortes SIN proyeccion (rd_base=0)', proj_params.get('n_sin_proyeccion', '')),
    ]
    for k, v in proj_items:
        ws_coef.write(row, 0, k, fmt_key)
        if isinstance(v, (int, float)) and not isinstance(v, bool):
            ws_coef.write(row, 1, v, fmt_val)
        else:
            ws_coef.write(row, 1, str(v), fmt_text_coef)
        row += 1

    row += 1
    ws_coef.merge_range(row, 0, row, 1, 'LAMBDA MLE BINOMIAL', fmt_section)
    row += 1
    if lambda_params:
        lam_items = [
            ('lambda_MLE', lambda_params.get('lambda_mle', '')),
            ('SE(lambda)', lambda_params.get('se_lambda', '')),
            ('IC 95% lo', lambda_params.get('ci_95_lo', '')),
            ('IC 95% hi', lambda_params.get('ci_95_hi', '')),
            ('Wald z', lambda_params.get('wald_z', '')),
            ('Wald p-value', lambda_params.get('wald_p', '')),
            ('LRT chi2', lambda_params.get('lrt_chi2', '')),
            ('LRT p-value', lambda_params.get('lrt_p', '')),
            ('H0: lambda=1.0 rechazado', str(lambda_params.get('reject_h0_005', ''))),
            ('MAE MLE (bps)', lambda_params.get('mae_mle_bps', '')),
            ('MAE lambda=1 (bps)', lambda_params.get('mae_lam1_bps', '')),
            ('Bias MLE (bps)', lambda_params.get('bias_mle_bps', '')),
            ('Bias lambda=1 (bps)', lambda_params.get('bias_lam1_bps', '')),
            ('AIC MLE', lambda_params.get('aic_mle', '')),
            ('AIC lambda=1', lambda_params.get('aic_lam1', '')),
            ('n_months', lambda_params.get('n_months', '')),
            ('window', lambda_params.get('window', '')),
        ]
        for k, v in lam_items:
            ws_coef.write(row, 0, k, fmt_key)
            if isinstance(v, float):
                ws_coef.write(row, 1, v, fmt_val)
            else:
                ws_coef.write(row, 1, str(v), fmt_text_coef)
            row += 1
    else:
        ws_coef.write(row, 0, 'No lambda MLE results found', fmt_text_coef)
        row += 1

    row += 1
    ws_coef.merge_range(row, 0, row, 1, 'MACRO PROBIT', fmt_section)
    row += 1
    macro_betas = macro_params.get('betas_estimated', [])
    ws_coef.write(row, 0, 'Variable', fmt_key)
    ws_coef.write(row, 1, MACRO_CHAMPION_VARS[0] if MACRO_CHAMPION_VARS else '', fmt_text_coef)
    row += 1
    ws_coef.write(row, 0, 'beta_0 (intercepto)', fmt_key)
    ws_coef.write(row, 1, macro_betas[0] if len(macro_betas) > 0 else '', fmt_val)
    row += 1
    ws_coef.write(row, 0, 'beta_1 (coeficiente)', fmt_key)
    ws_coef.write(row, 1, macro_betas[1] if len(macro_betas) > 1 else '', fmt_val)
    row += 1
    ws_coef.write(row, 0, 'R2', fmt_key)
    ws_coef.write(row, 1, macro_params.get('r2', ''), fmt_val)
    row += 1
    ws_coef.write(row, 0, 'R2 adj', fmt_key)
    ws_coef.write(row, 1, macro_params.get('r2_adj', ''), fmt_val)
    row += 1
    ws_coef.write(row, 0, 'DW', fmt_key)
    ws_coef.write(row, 1, macro_params.get('dw', ''), fmt_val)
    row += 1

    row += 1
    ws_coef.merge_range(row, 0, row, 1, 'BETA CALIBRACION POR SEGMENTO', fmt_section)
    row += 1
    for seg, seg_p in cal_params.get('segments', {}).items():
        ws_coef.write(row, 0, f'{seg}: a', fmt_key)
        ws_coef.write(row, 1, seg_p.get('a', ''), fmt_val)
        row += 1
        ws_coef.write(row, 0, f'{seg}: b', fmt_key)
        ws_coef.write(row, 1, seg_p.get('b', ''), fmt_val)
        row += 1
        ws_coef.write(row, 0, f'{seg}: m', fmt_key)
        ws_coef.write(row, 1, seg_p.get('m', ''), fmt_val)
        row += 1
        ws_coef.write(row, 0, f'{seg}: probit_delta', fmt_key)
        ws_coef.write(row, 1, seg_p.get('probit_delta', ''), fmt_val)
        row += 1

    row += 1
    ws_coef.merge_range(row, 0, row, 1, 'DRIVER PROBIT ADITIVO (Z1)', fmt_section)
    row += 1
    driver_coefs = pit_params.get('z1_driver_coefs', {})
    ws_coef.write(row, 0, 'delta_0 (intercepto)', fmt_key)
    ws_coef.write(row, 1, driver_coefs.get('delta_0', ''), fmt_val)
    row += 1
    for drv_name, beta in driver_coefs.get('driver_betas', {}).items():
        ws_coef.write(row, 0, f'delta({drv_name})', fmt_key)
        ws_coef.write(row, 1, beta, fmt_val)
        row += 1
    ws_coef.write(row, 0, 'selected_drivers', fmt_key)
    ws_coef.write(row, 1, str(driver_coefs.get('selected_drivers', [])), fmt_text_coef)
    row += 1

    row += 1
    ws_coef.merge_range(row, 0, row, 1, 'RESUMEN CALIBRACION', fmt_section)
    row += 1
    summary = [
        ('N Z1', pit_params.get('z1_n', '')),
        ('N Z2', pit_params.get('z2_n', '')),
        ('PD_PIT mean Z1', pit_params.get('pd_pit_mean_z1', '')),
        ('PD_PIT mean Z2', pit_params.get('pd_pit_mean_z2', '')),
        ('F cap quantile', pit_params.get('f_cap_quantile', '')),
        ('F cap [lo, hi]', f"[{pit_params.get('f_cap_lo', ''):.4f}, {pit_params.get('f_cap_hi', ''):.4f}]"),
    ]
    for k, v in summary:
        ws_coef.write(row, 0, k, fmt_key)
        if isinstance(v, float) and v < 1:
            ws_coef.write(row, 1, v, fmt_pct_coef)
        elif isinstance(v, (int, float)):
            ws_coef.write(row, 1, v, fmt_text_coef)
        else:
            ws_coef.write(row, 1, str(v), fmt_text_coef)
        row += 1

    row += 1
    ws_coef.merge_range(row, 0, row, 1, 'LRA POR SEGMENTO', fmt_section)
    row += 1
    ws_coef.write(row, 0, 'LRA global', fmt_key)
    ws_coef.write(row, 1, lra_params.get('lra_global', ''), fmt_pct_coef)
    row += 1
    for seg, lra_v in lra_params.get('lra_by_segment', {}).items():
        ws_coef.write(row, 0, f'LRA {seg}', fmt_key)
        ws_coef.write(row, 1, lra_v, fmt_pct_coef)
        row += 1

    row += 1
    ws_coef.merge_range(row, 0, row, 1,
                        'RHO POR SEGMENTO (MoM) — REFERENCIA, no usado en PD (producción aplica ρ global)',
                        fmt_section)
    row += 1
    for seg, seg_data in rho_params.get('rho_by_segment', {}).items():
        ws_coef.write(row, 0, f'rho_raw ({seg})', fmt_key)
        ws_coef.write(row, 1, seg_data.get('rho_raw', ''), fmt_val)
        row += 1

    print(f"  Sheet COEFICIENTES: {row} rows")

    # ── GLOBAL sheet ──
    global_df, global_inc = build_global_sheet(df)
    global_df.to_excel(writer, sheet_name='GLOBAL', index=False, startrow=1, header=False)
    ws = writer.sheets['GLOBAL']
    format_sheet(ws, global_df, writer, global_inc)
    print(f"  Sheet GLOBAL: {len(global_df)} rows, {len(global_df.columns)} cols")
    if global_inc:
        print(f"    Trimestres incompletos: {global_inc}")

    # ── Driver sheets ──
    for drv in DRIVER_COLS:
        if drv not in df.columns:
            print(f"  Sheet {drv}: SKIP (not in data)")
            continue
        drv_df, drv_inc = build_driver_sheet(df, drv)
        if len(drv_df) == 0:
            print(f"  Sheet {drv}: SKIP (empty)")
            continue
        sheet_name = drv[:31]
        drv_df.to_excel(writer, sheet_name=sheet_name, index=False, startrow=1, header=False)
        ws = writer.sheets[sheet_name]
        format_sheet(ws, drv_df, writer, drv_inc, NOTAS_DRIVER)
        print(f"  Sheet {sheet_name}: {len(drv_df)} rows, {len(drv_df.columns)} cols")

print(f"\nExport: {xlsx_path}")

print(f"\n{'=' * 60}")
print(f"  09 COMPLETADO — EXCEL RESUMEN TRIMESTRAL {SUBPRODUCTO_FILTER}")
print(f"{'=' * 60}")
