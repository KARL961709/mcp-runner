# =============================================================================
# 02 — Estimación rho Vasicek (método de momentos), Reenganche
# =============================================================================
# rho = Var(Phi^-1(RD_t)) / (1 + Var(Phi^-1(RD_t))); floor Basel IRB retail.
# Excluye COVID; mantiene el spike inflacionario (rho necesita la volatilidad).
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
    COHORTE_FIN, SEG_COL, SEG_VALUES,
    COVID_EXCL_MONTHS, EXCL_COVID_FOR_RHO, RHO_FLOOR,
)

np.random.seed(RANDOM_SEED)


def estimate_rho_mom(rd_series, excl_covid=True):
    rd_clean = rd_series.copy()
    if excl_covid:
        rd_clean = rd_clean[~rd_clean.index.isin(COVID_EXCL_MONTHS)]
    rd_vals = rd_clean.values
    rd_vals = rd_vals[(rd_vals > 0) & (rd_vals < 1)]
    y = norm.ppf(rd_vals)
    var_y = np.var(y, ddof=1)
    rho_raw = var_y / (1 + var_y)
    return rho_raw, var_y, len(rd_vals)


rd_mes = pd.read_csv(PATHS['csv'] / 'rd_mensual.csv')
rd_mes['codmes'] = rd_mes['codmes'].astype(str)
rd_series = pd.Series(rd_mes['rd'].values, index=rd_mes['codmes'].values)
rho_raw, var_y, n_meses = estimate_rho_mom(rd_series, excl_covid=EXCL_COVID_FOR_RHO)
rho_final = max(rho_raw, RHO_FLOOR)

print(f"02 Vasicek rho {SUBPRODUCTO_FILTER} | Var(Phi^-1 RD)={var_y:.6f} | "
      f"rho_raw={rho_raw:.6f} | rho_final={rho_final:.6f} "
      f"({'floor' if rho_raw < RHO_FLOOR else 'raw'}) | meses={n_meses}")

df_rd = pd.read_parquet(PATHS['parquets'] / 'rd_hist.parquet')
df_rd['codmes'] = df_rd['codmes'].astype(str)
df_rd_maduro = df_rd[df_rd['codmes'] <= COHORTE_FIN].copy()

rho_by_seg = {}
for seg in SEG_VALUES:
    rd_seg = df_rd_maduro[df_rd_maduro[SEG_COL] == seg]
    rd_seg_mes = rd_seg.groupby('codmes').agg(
        n=(TARGET_COL, 'count'),
        defaults=(TARGET_COL, 'sum'),
    ).reset_index()
    rd_seg_mes['rd'] = rd_seg_mes['defaults'] / rd_seg_mes['n']
    rd_seg_series = pd.Series(rd_seg_mes['rd'].values, index=rd_seg_mes['codmes'].astype(str).values)
    rho_seg_raw, var_seg, n_seg = estimate_rho_mom(rd_seg_series, excl_covid=EXCL_COVID_FOR_RHO)
    rho_seg_final = max(rho_seg_raw, RHO_FLOOR)
    rho_by_seg[seg] = {
        'rho_raw': float(rho_seg_raw),
        'rho_final': float(rho_seg_final),
        'var_y': float(var_seg),
        'n_meses': int(n_seg),
        'floor_applied': bool(rho_seg_raw < RHO_FLOOR),
    }
    print(f"  {seg:<7} rho_raw={rho_seg_raw:.6f} -> rho_final={rho_seg_final:.6f} ({n_seg} meses)")

output = {
    'product': SUBPRODUCTO_FILTER,
    'method': 'method_of_moments',
    'rho_raw': float(rho_raw),
    'rho_final': float(rho_final),
    'rho_floor': float(RHO_FLOOR),
    'floor_applied': bool(rho_raw < RHO_FLOOR),
    'var_phi_inv_rd': float(var_y),
    'n_meses': int(n_meses),
    'covid_excluded': EXCL_COVID_FOR_RHO,
    'rho_by_segment': rho_by_seg,
}
with open(PATHS['json'] / 'vasicek_rho.json', 'w') as f:
    json.dump(output, f, indent=2)
print("  export: vasicek_rho.json")
