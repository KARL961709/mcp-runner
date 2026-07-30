# =============================================================================
# 08 — Tabla final PD calibrada (Reenganche)
# =============================================================================
# Consolida PD por driver-celda y serie mensual agregada.
# Export: pd_final.parquet, pd_summary_drivers.csv, pd_mensual_final.csv, pd_final.json
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
    RANDOM_SEED, PATHS, TARGET_COL, SCORE_COL, SUBPRODUCTO_FILTER,
    SEG_COL, DRIVER_COLS, LAMBDA_PIT, COHORTE_FIN,
)

np.random.seed(RANDOM_SEED)

df = pd.read_parquet(PATHS['parquets'] / 'full_calibrated.parquet')
with open(PATHS['json'] / 'calibracion_beta.json') as f:
    cal_json = json.load(f)
with open(PATHS['json'] / 'vasicek_rho.json') as f:
    rho_json = json.load(f)
with open(PATHS['json'] / 'lra.json') as f:
    lra_json = json.load(f)
with open(PATHS['json'] / 'macro_model.json') as f:
    macro_json = json.load(f)

df_z1 = df[df['codmes'] <= COHORTE_FIN].copy()
df_z2 = df[df['codmes'] > COHORTE_FIN].copy()
pd_col = 'pd_pit'

# Resumen por driver-celda (Z1 + proyeccion Z2)
summary_rows = []
for drv in DRIVER_COLS:
    if drv not in df_z1.columns:
        continue
    df_drv = df_z1[df_z1[drv].notna()]
    for val in sorted(df_drv[drv].unique(), key=str):
        mask = df_drv[drv] == val
        n = mask.sum()
        if n == 0:
            continue
        row = {
            'driver': drv,
            'celda': str(val),
            'n_z1': int(n),
            'rd_obs': float(df_drv.loc[mask, TARGET_COL].mean()),
            'pd_ree_mean': float(df_drv.loc[mask, SCORE_COL].mean()),
            'pd_cal_mean': float(df_drv.loc[mask, 'pd_cal'].mean()),
            'pd_ttc_mean': float(df_drv.loc[mask, 'pd_ttc'].mean()),
        }
        if pd_col in df_drv.columns:
            row['pd_pit_mean'] = float(df_drv.loc[mask, pd_col].mean())
            row['gap_bps'] = float((row['pd_pit_mean'] - row['rd_obs']) * 10000)
        if drv in df_z2.columns:
            mask_z2 = df_z2[drv].astype(str) == str(val)
            n_z2 = mask_z2.sum()
            row['n_z2'] = int(n_z2)
            if n_z2 > 0 and pd_col in df_z2.columns:
                row['pd_pit_z2_mean'] = float(df_z2.loc[mask_z2, pd_col].mean())
        summary_rows.append(row)
summary_df = pd.DataFrame(summary_rows)

# Serie mensual agregada
agg = df.groupby('codmes').agg(
    n=(SCORE_COL, 'count'),
    pd_ree_mean=(SCORE_COL, 'mean'),
    pd_pit_mean=('pd_pit', 'mean') if 'pd_pit' in df.columns else (SCORE_COL, 'mean'),
).reset_index()
if TARGET_COL in df.columns:
    agg_target = df[df[TARGET_COL].notna()].groupby('codmes')[TARGET_COL].agg(['mean', 'sum']).reset_index()
    agg_target.columns = ['codmes', 'rd', 'defaults']
    agg = agg.merge(agg_target, on='codmes', how='left')
agg = agg.sort_values('codmes').reset_index(drop=True)

print(f"08 Tabla final {SUBPRODUCTO_FILTER} | total={len(df):,} | Z1={len(df_z1):,} | Z2={len(df_z2):,} | "
      f"PD_pit Z1={df_z1['pd_pit'].mean()*100:.4f}% Z2={df_z2['pd_pit'].mean()*100:.4f}%")

# Export
output_cols = ['codmes', SCORE_COL, SEG_COL] + \
    [d for d in DRIVER_COLS if d in df.columns and d != SEG_COL] + \
    ['pd_cal', 'pd_ttc', 'pd_ttc_adj', 'pd_pit', 'ft', 'rho_i']
output_cols = [c for c in output_cols if c in df.columns]
if TARGET_COL in df.columns:
    output_cols.insert(2, TARGET_COL)

df[output_cols].copy().to_parquet(PATHS['parquets'] / 'pd_final.parquet', index=False)
summary_df.to_csv(PATHS['csv'] / 'pd_summary_drivers.csv', index=False)
agg.to_csv(PATHS['csv'] / 'pd_mensual_final.csv', index=False)

final_json = {
    'product': SUBPRODUCTO_FILTER,
    'chain': 'pd_ree → BetaCal(tipo_ingreso) → probit_δ → driver_cal → Vasicek_PIT',
    'rho': rho_json['rho_final'],
    'lambda': LAMBDA_PIT,
    'macro_vars': macro_json['champion_variables'],
    'n_z1': int(len(df_z1)),
    'n_z2': int(len(df_z2)),
    'n_total': int(len(df)),
    'pd_pit_mean_z1': float(df_z1['pd_pit'].mean()),
    'pd_pit_mean_z2': float(df_z2['pd_pit'].mean()),
    'rd_z1': float(df_z1[TARGET_COL].mean()),
    'calibration_params': cal_json['segments'],
    'driver_summary': summary_rows,
}
with open(PATHS['json'] / 'pd_final.json', 'w') as f:
    json.dump(final_json, f, indent=2, default=str)
print("  export: pd_final.parquet, pd_summary_drivers.csv, pd_mensual_final.csv, pd_final.json")
