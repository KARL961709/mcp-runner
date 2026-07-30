# =============================================================================
# 04 — Beta Calibration por segmento tipo_ingreso_dep (Reenganche)
# =============================================================================
# Beta Cal 3 parámetros (Kull 2017): pd_cal = sigmoid(c + a*log(p) - b*log(1-p)).
# Fit separado por segmento {DEP, NO DEP} via MLE (statsmodels).
# Level check: si |mean(pd_cal) - LRA| > umbral, se aplica shift probit (delta).
# CAMBIO 2026-07-27 (ACUERDOS A56, A57):
#   - BETACAL_MONOTONE impone a>=0, b>=0 (condicion exacta de monotonicidad de
#     Kull). Resuelto por KKT real con cotas, NO por clip: el clip no reajusta
#     el intercepto y discrepa hasta 0.24 en PD media. Si el MLE libre ya es
#     factible, el resultado es identico bit a bit.
#   - LEVEL_CHECK_THRESHOLD pasa de 50 bps a 0: se ancla SIEMPRE, sin parametro
#     libre y con los dos segmentos tratados igual.
# =============================================================================

import json
import sys
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import norm
from scipy.optimize import brentq

warnings.filterwarnings("ignore", category=FutureWarning)

_PROJECT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_PROJECT / 'src'))

from config import (
    RANDOM_SEED, PATHS, TARGET_COL, SCORE_COL, SUBPRODUCTO_FILTER,
    SEG_COL, SEG_VALUES, LEVEL_CHECK_THRESHOLD, BETACAL_MONOTONE,
)
from calibration import BetaCalibrator

np.random.seed(RANDOM_SEED)

# 1. Carga
df_z1 = pd.read_parquet(PATHS['parquets'] / 'z1.parquet').copy()
with open(PATHS['json'] / 'lra.json') as f:
    lra_json = json.load(f)
lra_by_seg = lra_json['lra_by_segment']
lra_global = lra_json['lra_global']

print(f"04 Beta Calibration {SUBPRODUCTO_FILTER} | Z1={len(df_z1):,} | LRA global={lra_global*100:.4f}%")

# 2. Beta Cal por segmento
seg_results = {}
for seg in SEG_VALUES:
    mask_seg = df_z1[SEG_COL] == seg
    n_seg = int(mask_seg.sum())
    lra_seg = lra_by_seg[seg]

    p_raw = df_z1.loc[mask_seg, SCORE_COL].values.astype(float)
    y_true = df_z1.loc[mask_seg, TARGET_COL].values.astype(float)
    rd_obs = y_true.mean()

    beta_cal = BetaCalibrator(monotone=BETACAL_MONOTONE)
    beta_cal.fit(p_raw, y_true)
    pd_cal = np.clip(beta_cal.predict(p_raw), 1e-9, 1 - 1e-9)

    sort_idx = np.argsort(p_raw)
    is_mono = bool(np.all(np.diff(pd_cal[sort_idx]) >= -1e-10))

    level_gap = pd_cal.mean() - lra_seg
    level_gap_bps = level_gap * 10000

    probit_delta = 0.0
    if abs(level_gap) <= LEVEL_CHECK_THRESHOLD:
        pd_ttc = pd_cal.copy()
    else:
        z_cal = norm.ppf(pd_cal)

        def _probit_obj(delta):
            return norm.cdf(z_cal + delta).mean() - lra_seg

        probit_delta = brentq(_probit_obj, -2.0, 2.0)
        pd_ttc = np.clip(norm.cdf(z_cal + probit_delta), 1e-9, 1 - 1e-9)

    df_z1.loc[mask_seg, 'pd_cal'] = pd_cal
    df_z1.loc[mask_seg, 'pd_ttc'] = pd_ttc

    seg_results[seg] = {
        'a': float(beta_cal.a_),
        'b': float(beta_cal.b_),
        'm': float(beta_cal.c_),
        'probit_delta': float(probit_delta),
        'level_gap_bps': float(level_gap_bps),
        'lra': float(lra_seg),
        'pd_cal_mean': float(pd_cal.mean()),
        'pd_ttc_mean': float(pd_ttc.mean()),
        'n': n_seg,
        'rd_obs': float(rd_obs),
        'monotonic': is_mono,
        'restriccion_monotona_activa': bool(getattr(beta_cal, 'restriccion_activa_', False)),
    }

    print(f"  {seg:<7} n={n_seg:>6,}  a={beta_cal.a_:.4f} b={beta_cal.b_:.4f} m={beta_cal.c_:.4f}  "
          f"pd_cal={pd_cal.mean()*100:.4f}%  LRA={lra_seg*100:.4f}%  gap={level_gap_bps:+.1f}bps  "
          f"delta={probit_delta:.4f}  mono={'si' if is_mono else 'no'}")

# 3. Export
cal_output = {
    'product': SUBPRODUCTO_FILTER,
    'method': 'beta_calibration_kull_2017',
    'segmentation': SEG_COL,
    'segments': seg_results,
    'level_check_threshold_bps': float(LEVEL_CHECK_THRESHOLD * 10000),
    'betacal_monotone': bool(BETACAL_MONOTONE),
}
with open(PATHS['json'] / 'calibracion_beta.json', 'w') as f:
    json.dump(cal_output, f, indent=2)
df_z1.to_parquet(PATHS['parquets'] / 'z1_calibrated.parquet', index=False)
print("  export: calibracion_beta.json, z1_calibrated.parquet")
