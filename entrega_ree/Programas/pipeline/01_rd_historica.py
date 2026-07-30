# =============================================================================
# 01 — RD histórica mensual + LRA (Reenganche)
# =============================================================================
# RD 12m mensual (serie larga), LRA global y por celda de cada driver.
# LRA: mediana excluyendo COVID + spike inflacionario (ECB par. 236(d)).
# =============================================================================

import json
import sys
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import norm

warnings.filterwarnings("ignore", category=FutureWarning)

_PROJECT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_PROJECT / 'src'))

from config import (
    RANDOM_SEED, PATHS, TARGET_COL, SUBPRODUCTO_FILTER,
    COHORTE_FIN, SEG_COL, SEG_VALUES, DRIVER_COLS,
    COVID_EXCL_MONTHS, LRA_EXCL_MONTHS, LRA_METHOD,
)

np.random.seed(RANDOM_SEED)
_agg = 'median' if LRA_METHOD == 'median' else 'mean'


def _lra(s):
    return s.median() if _agg == 'median' else s.mean()


df_rd = pd.read_parquet(PATHS['parquets'] / 'rd_hist.parquet')
df_rd['codmes'] = df_rd['codmes'].astype(str)
df_rd_maduro = df_rd[df_rd['codmes'] <= COHORTE_FIN].copy()

# RD mensual global
rd_mes = df_rd_maduro.groupby('codmes').agg(
    n=(TARGET_COL, 'count'),
    defaults=(TARGET_COL, 'sum'),
).reset_index()
rd_mes['rd'] = rd_mes['defaults'] / rd_mes['n']
rd_mes = rd_mes.sort_values('codmes').reset_index(drop=True)
rd_mes['is_covid'] = rd_mes['codmes'].isin(COVID_EXCL_MONTHS)
rd_mes['y'] = norm.ppf(np.clip(rd_mes['rd'], 1e-6, 1 - 1e-6))

# LRA global (variantes de exclusion para referencia)
rd_lra_excl = rd_mes[~rd_mes['codmes'].isin(LRA_EXCL_MONTHS)].copy()
rd_no_covid = rd_mes[~rd_mes['is_covid']].copy()
lra_global = _lra(rd_lra_excl['rd'])
lra_global_all = _lra(rd_mes['rd'])
lra_global_mean = rd_lra_excl['rd'].mean()
lra_global_no_covid_only = _lra(rd_no_covid['rd'])

print(f"01 RD historica {SUBPRODUCTO_FILTER} | meses={len(rd_mes)} | "
      f"LRA global ({_agg}, excl COVID+spike)={lra_global*100:.4f}% | "
      f"meses excluidos={len(rd_mes)-len(rd_lra_excl)}")

# LRA por celda de driver
lra_by_driver = {}
for drv in DRIVER_COLS:
    if drv not in df_rd_maduro.columns:
        continue
    rd_drv = df_rd_maduro.groupby(['codmes', drv]).agg(
        n=(TARGET_COL, 'count'),
        defaults=(TARGET_COL, 'sum'),
    ).reset_index()
    rd_drv['rd'] = rd_drv['defaults'] / rd_drv['n']
    rd_drv['is_lra_excl'] = rd_drv['codmes'].isin(LRA_EXCL_MONTHS)
    lra_drv = {}
    for val in sorted(df_rd_maduro[drv].dropna().unique(), key=str):
        rd_val = rd_drv[(rd_drv[drv] == val) & (~rd_drv['is_lra_excl'])]
        if len(rd_val) == 0:
            continue
        lra_drv[str(val)] = {
            'lra': float(_lra(rd_val['rd'])),
            'n_meses': int(len(rd_val)),
            'n_obs_total': int(rd_val['n'].sum()),
        }
    lra_by_driver[drv] = lra_drv

# LRA por segmento primario
lra_by_seg = {}
for seg in SEG_VALUES:
    rd_seg = df_rd_maduro[df_rd_maduro[SEG_COL] == seg]
    rd_seg_mes = rd_seg.groupby('codmes').agg(
        n=(TARGET_COL, 'count'),
        defaults=(TARGET_COL, 'sum'),
    ).reset_index()
    rd_seg_mes['rd'] = rd_seg_mes['defaults'] / rd_seg_mes['n']
    rd_seg_mes_nc = rd_seg_mes[~rd_seg_mes['codmes'].isin(LRA_EXCL_MONTHS)]
    lra_by_seg[seg] = float(_lra(rd_seg_mes_nc['rd']))

rd_mes.to_csv(PATHS['csv'] / 'rd_mensual.csv', index=False)
lra_output = {
    'product': SUBPRODUCTO_FILTER,
    'lra_method': LRA_METHOD,
    'lra_global': float(lra_global),
    'lra_global_mean': float(lra_global_mean),
    'lra_global_excl_covid_only': float(lra_global_no_covid_only),
    'lra_global_incl_all': float(lra_global_all),
    'n_meses': int(len(rd_lra_excl)),
    'codmes_range': [rd_lra_excl['codmes'].iloc[0], rd_lra_excl['codmes'].iloc[-1]],
    'exclusions': {
        'covid': COVID_EXCL_MONTHS,
        'inflation_spike': [m for m in LRA_EXCL_MONTHS if m not in COVID_EXCL_MONTHS],
        'total_months_excluded': len(LRA_EXCL_MONTHS),
    },
    'lra_by_segment': lra_by_seg,
    'lra_by_driver': lra_by_driver,
}
with open(PATHS['json'] / 'lra.json', 'w') as f:
    json.dump(lra_output, f, indent=2, default=str)
print("  export: rd_mensual.csv, lra.json")
