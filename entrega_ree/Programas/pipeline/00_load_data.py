# =============================================================================
# 00 — Carga y partición de datos (Reenganche)
# =============================================================================
# CAMBIO 2026-07-27: el maestro reconstruido YA NO viene pre-filtrado. Trae el
# perímetro reenganche completo (flg_scope_ree=1, 88 meses) con la población
# como COLUMNA (flg_clean), no como recorte. El recorte se aplica ACÁ.
# La definición vive en config.filtro_poblacion() — un solo lugar, porque 10
# (chain-ladder) lee el mismo maestro y debe recortar igual o proyecta sobre
# otra población que la que calibró.
#   rd_hist (201901-COHORTE_FIN): target, con o sin pd -> LRA, rho, macro
#   z1      (COHORTE_INI-COHORTE_FIN): target y pd     -> calibracion
#   z2      (Z2_INI-Z2_FIN): pd, sin target            -> proyeccion
# Las fronteras son dos y distintas: COHORTE_FIN = madurez, RD_HIST_FIN = dato.
# =============================================================================

import json
import sys
import warnings
from pathlib import Path

import numpy as np
import pandas as pd

warnings.filterwarnings("ignore", category=FutureWarning)

_PROJECT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_PROJECT / 'src'))

from config import (
    RANDOM_SEED, PATHS, MASTER_PARQUET, TARGET_COL, SCORE_COL,
    SUBPRODUCTO_FILTER, COHORTE_INI, COHORTE_FIN,
    Z2_INI, Z2_FIN, RD_HIST_INI, SEG_COL, SEG_VALUES,
    CLEAN_MODE, filtro_poblacion,
)

np.random.seed(RANDOM_SEED)

df = pd.read_parquet(MASTER_PARQUET)
df['codmes'] = df['codmes'].astype(str)

pob = filtro_poblacion(df)

df_rd = df[
    pob &
    (df['codmes'] >= RD_HIST_INI) &
    (df['codmes'] <= COHORTE_FIN) &
    (df[TARGET_COL].notna())
].copy()

df_z1 = df[
    pob &
    (df['codmes'] >= COHORTE_INI) &
    (df['codmes'] <= COHORTE_FIN) &
    (df[SCORE_COL].notna()) &
    (df[TARGET_COL].notna())
].copy()

df_z2 = df[
    pob &
    (df['codmes'] >= Z2_INI) &
    (df['codmes'] <= Z2_FIN) &
    (df[SCORE_COL].notna())
].copy()

# Ratchet: flg_calib se construyo aguas arriba como
#   flg_clean <> 99 AND pd_raw IS NOT NULL AND falla_madurez_12 = 0
# asi que dentro de la poblacion debe coincidir EXACTAMENTE con el recorte de
# Z1. Si divergen, el maestro y este script dejaron de significar lo mismo y
# hay que parar, no seguir con numeros plausibles.
if 'flg_calib' in df.columns:
    _esp = df[pob & (df['codmes'] >= COHORTE_INI) & (df['codmes'] <= COHORTE_FIN)]
    _n_mismatch = int((_esp['flg_calib'].astype(int) !=
                       (_esp[SCORE_COL].notna() & _esp[TARGET_COL].notna()).astype(int)).sum())
    if _n_mismatch:
        raise AssertionError(
            f"flg_calib discrepa del recorte de Z1 en {_n_mismatch:,} filas. "
            "El maestro y 00_load_data dejaron de significar lo mismo."
        )

_n99 = int((df['flg_clean'] == 99).sum())
_n0 = int((df['flg_clean'] == 0).sum())
print(f"00 Load {SUBPRODUCTO_FILTER} | master={len(df):,} "
      f"(scope99={_n99:,} dirty={_n0:,} modo={CLEAN_MODE}) -> poblacion={int(pob.sum()):,}")
print(f"   rd_hist={len(df_rd):,} [{RD_HIST_INI}-{COHORTE_FIN}] | "
      f"Z1={len(df_z1):,} [{COHORTE_INI}-{COHORTE_FIN}] (RD={df_z1[TARGET_COL].mean()*100:.2f}%) | "
      f"Z2={len(df_z2):,} [{Z2_INI}-{Z2_FIN}]")
for seg in SEG_VALUES:
    m = df_z1[SEG_COL] == seg
    print(f"  {seg:<7} n={int(m.sum()):>6,}  RD={df_z1.loc[m, TARGET_COL].mean()*100:.2f}%")

dq = {
    'product': SUBPRODUCTO_FILTER,
    'master_shape': list(df.shape),
    'poblacion': {
        'clean_mode': CLEAN_MODE,
        'expr': 'flg_clean == 1' if CLEAN_MODE == 'clean' else 'flg_clean != 99',
        'master_n': int(len(df)),
        'master_scope99': _n99,
        'master_dirty': _n0,
        'poblacion_n': int(pob.sum()),
    },
    'filters_applied': {
        'rd_hist': f'poblacion & codmes [{RD_HIST_INI},{COHORTE_FIN}] & {TARGET_COL}.notna()',
        'z1': f'poblacion & codmes [{COHORTE_INI},{COHORTE_FIN}] & {SCORE_COL}.notna() & {TARGET_COL}.notna()',
        'z2': f'poblacion & codmes [{Z2_INI},{Z2_FIN}] & {SCORE_COL}.notna()',
        'note': ('El maestro reconstruido NO viene pre-filtrado: trae el perimetro '
                 'reenganche completo con la poblacion como columna (flg_clean). '
                 'El recorte se aplica aqui via config.filtro_poblacion(). '
                 'flg_calib ya no es "es reenganche" sino "entra al fit", y se '
                 'verifica contra el recorte de Z1 en vez de asumirse.'),
    },
    'z1_n': int(len(df_z1)),
    'z2_n': int(len(df_z2)),
    'rd_hist_n': int(len(df_rd)),
    'z1_rd': float(df_z1[TARGET_COL].mean()),
    'z1_gini': None,
    'z1_score_mean': float(df_z1[SCORE_COL].mean()),
    'z1_codmes_range': [df_z1['codmes'].min(), df_z1['codmes'].max()],
    'z2_codmes_range': [df_z2['codmes'].min(), df_z2['codmes'].max()],
    'driver_stats': {},
}
for seg in SEG_VALUES:
    m = df_z1[SEG_COL] == seg
    dq['driver_stats'].setdefault(SEG_COL, {})[seg] = {
        'n': int(m.sum()),
        'rd': float(df_z1.loc[m, TARGET_COL].mean()),
    }

df_rd.to_parquet(PATHS['parquets'] / 'rd_hist.parquet', index=False)
df_z1.to_parquet(PATHS['parquets'] / 'z1.parquet', index=False)
df_z2.to_parquet(PATHS['parquets'] / 'z2.parquet', index=False)
with open(PATHS['json'] / 'data_quality.json', 'w') as f:
    json.dump(dq, f, indent=2, default=str)
print("  export: rd_hist/z1/z2.parquet, data_quality.json")
