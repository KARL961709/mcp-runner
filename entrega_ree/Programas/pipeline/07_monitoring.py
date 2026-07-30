# =============================================================================
# 07 — Monitoring y backtesting (Reenganche)
# =============================================================================
# EC relativo, Gini, Brier, ECE global y por driver. Backtest trimestral.
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
    SEG_COL, SEG_VALUES, DRIVER_COLS, COHORTE_INI, COHORTE_FIN,
)
from monitoring import ec_relativo, ec_status, jeffreys_pass, EC_MULT_DEFAULT
from metrics import gini, ece, brier

np.random.seed(RANDOM_SEED)

df_full = pd.read_parquet(PATHS['parquets'] / 'full_calibrated.parquet')
df_z1 = df_full[
    (df_full['codmes'].astype(str) >= COHORTE_INI) &
    (df_full['codmes'].astype(str) <= COHORTE_FIN)
].copy()

y = df_z1[TARGET_COL].values
p_pit = df_z1['pd_pit'].values
p_ree = df_z1[SCORE_COL].values
gini_pit = gini(y, p_pit)
gini_ree = gini(y, p_ree)
brier_pit = brier(y, p_pit)
ece_pit = ece(y, p_pit)
ec_global = ec_relativo(y.mean(), p_pit.mean())
k_glob, n_glob = int(y.sum()), len(y)
j_glob = jeffreys_pass(k_glob, n_glob, p_pit.mean())
st_glob = ec_status(ec_global, bool(j_glob) if j_glob is not None else False)

print(f"07 Monitoring {SUBPRODUCTO_FILTER} | Z1={len(df_z1):,} | RD={y.mean()*100:.4f}% | "
      f"PD_pit={p_pit.mean()*100:.4f}% | EC={ec_global:+.4f} {st_glob.upper()} | "
      f"Gini pit={gini_pit:.4f} ree={gini_ree:.4f} | Brier={brier_pit:.6f} | ECE={ece_pit:.4f}")
for seg in SEG_VALUES:
    mask = df_z1[SEG_COL] == seg
    n_seg = int(mask.sum())
    k_seg = int(df_z1.loc[mask, TARGET_COL].sum())
    rd_seg = df_z1.loc[mask, TARGET_COL].mean()
    pd_seg = df_z1.loc[mask, 'pd_pit'].mean()
    ec_seg = ec_relativo(rd_seg, pd_seg)
    j_seg = jeffreys_pass(k_seg, n_seg, pd_seg)
    st_seg = ec_status(ec_seg, bool(j_seg) if j_seg is not None else False)
    print(f"  {seg:<7} RD={rd_seg*100:.4f}% PD={pd_seg*100:.4f}% EC={ec_seg:+.4f} "
          f"J={'PASS' if j_seg else ('FAIL' if j_seg is not None else 'NA')} {st_seg.upper()} n={n_seg:,}")

# EC por driver
ec_driver_results = []
pd_col = 'pd_pit'
for drv in DRIVER_COLS:
    if drv not in df_z1.columns:
        continue
    df_drv = df_z1[df_z1[drv].notna()]
    for val in sorted(df_drv[drv].unique(), key=str):
        mask = df_drv[drv] == val
        n = int(mask.sum())
        k = int(df_drv.loc[mask, TARGET_COL].sum())
        rd = df_drv.loc[mask, TARGET_COL].mean()
        pd_val = df_drv.loc[mask, pd_col].mean()
        ec_val = ec_relativo(rd, pd_val)
        j = jeffreys_pass(k, n, pd_val)
        ec_driver_results.append({
            'driver': drv, 'celda': str(val), 'n': n, 'defaults': k,
            'rd': float(rd), 'pd': float(pd_val), 'ec': float(ec_val),
            'jeffreys': 'PASS' if j else ('FAIL' if j is not None else ''),
            'status': ec_status(ec_val, bool(j) if j is not None else False),
        })

# Backtesting trimestral
df_z1_bt = df_z1.copy()
df_z1_bt['trim'] = df_z1_bt['codmes'].apply(lambda cm: f"{cm[:4]}Q{(int(cm[4:6])-1)//3+1}")
bt_trim = df_z1_bt.groupby('trim').agg(
    n=(TARGET_COL, 'count'),
    defaults=(TARGET_COL, 'sum'),
    pd_pit_mean=(pd_col, 'mean'),
).reset_index()
bt_trim['rd'] = bt_trim['defaults'] / bt_trim['n']
bt_trim['ec'] = (bt_trim['rd'] - bt_trim['pd_pit_mean']) / bt_trim['pd_pit_mean']
_bt_j, _bt_st = [], []
for _k, _n, _pdv in zip(bt_trim['defaults'], bt_trim['n'], bt_trim['pd_pit_mean']):
    _jp = jeffreys_pass(int(_k), int(_n), _pdv)
    _bt_j.append('PASS' if _jp else ('FAIL' if _jp is not None else ''))
    _rd = _k / _n if _n > 0 else float('nan')
    _bt_st.append(ec_status(ec_relativo(_rd, _pdv), bool(_jp) if _jp is not None else False))
bt_trim['jeffreys'] = _bt_j
bt_trim['status'] = _bt_st

monitoring_output = {
    'product': SUBPRODUCTO_FILTER,
    'gini_pit': float(gini_pit),
    'gini_ree': float(gini_ree),
    'brier_pit': float(brier_pit),
    'ece_pit': float(ece_pit),
    'ec_global': float(ec_global),
    'ec_global_status': st_glob,
    'ec_bands_mult': EC_MULT_DEFAULT,
    'ec_bands_mult_status': ('PROVISIONAL: definicion formal (x1 vs x2) y validacion Monte Carlo '
                             'pendientes en Lineamientos de Desarrollo y Monitoreo de Calibracion (deadline Jun-2026)'),
    'ec_bands_pct': {'verde': [-30, 20], 'amarillo_neg': [-60, -30], 'amarillo_pos': [20, 40]},
    'jeffreys_rule': 'p>5% bilateral (PD dentro IC95% de Beta(d+0.5, n-d+0.5)) baja un nivel',
    'ec_by_driver': ec_driver_results,
    'backtesting_trimestral': bt_trim.to_dict('records'),
}
with open(PATHS['json'] / 'monitoring.json', 'w') as f:
    json.dump(monitoring_output, f, indent=2, default=str)
print("  export: monitoring.json")
