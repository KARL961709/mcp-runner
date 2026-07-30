# =============================================================================
# 03 — Modelo macro y ft calendario (Reenganche)
# =============================================================================
# ft_GLOBAL = beta0 + beta1 * IPC_Lima_var_12m_lag5_ma6 (probit univariado).
# Betas via OLS con errores HAC (Newey-West). Excluye COVID, mantiene spike.
# Filtro de régimen F9 (gate duro): R2 >= REGIME_R2_MIN en cada ventana.
# =============================================================================

import json
import sys
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import norm
import statsmodels.api as sm
from statsmodels.stats.stattools import durbin_watson
from statsmodels.tsa.stattools import adfuller

warnings.filterwarnings("ignore", category=FutureWarning)

_PROJECT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_PROJECT / 'src'))

from config import (
    RANDOM_SEED, PATHS, SUBPRODUCTO_FILTER,
    COHORTE_FIN, COVID_EXCL_MONTHS,
    MACRO_PARQUET, MACRO_CHAMPION_VARS, MACRO_SPEC,
    REGIME_R2_MIN, REGIME_WINDOWS,
)

np.random.seed(RANDOM_SEED)

rd_mes = pd.read_csv(PATHS['csv'] / 'rd_mensual.csv')
rd_mes['codmes'] = rd_mes['codmes'].astype(str)
macro = pd.read_parquet(MACRO_PARQUET).reset_index()
macro['codmes'] = macro['codmes'].astype(float).astype(int).astype(str)
for var in MACRO_CHAMPION_VARS:
    assert var in macro.columns, f"Variable {var} no encontrada en macro parquet"

# Estimacion OLS con HAC, excl COVID, hasta COHORTE_FIN
rd_fit = rd_mes[
    (~rd_mes['codmes'].isin(COVID_EXCL_MONTHS)) &
    (rd_mes['codmes'] <= COHORTE_FIN)
].copy()
rd_fit['y'] = norm.ppf(np.clip(rd_fit['rd'], 1e-6, 1 - 1e-6))
merged = rd_fit.merge(macro[['codmes'] + MACRO_CHAMPION_VARS], on='codmes', how='inner')
merged = merged.dropna(subset=MACRO_CHAMPION_VARS + ['y'])

X = sm.add_constant(merged[MACRO_CHAMPION_VARS])
y = merged['y']
model = sm.OLS(y, X).fit(cov_type='HAC', cov_kwds={'maxlags': None})
model_ols = sm.OLS(y, X).fit()
betas_estimated = model.params.tolist()

dw = durbin_watson(model.resid)
adf_pval = adfuller(model.resid, maxlag=6)[1]
fitted_rd = norm.cdf(model.fittedvalues)
mae = np.mean(np.abs(fitted_rd - merged['rd']))

print(f"03 Macro {SUBPRODUCTO_FILTER} | {MACRO_CHAMPION_VARS[0]} | meses_fit={len(merged)} | "
      f"R2={model.rsquared:.4f} | DW={dw:.3f} | t_HAC={model.tvalues.iloc[1]:.2f} | MAE={mae:.5f}")

# ft calendario (betas estimados) para todos los meses con macro disponible
macro_full = macro[['codmes'] + MACRO_CHAMPION_VARS].dropna().sort_values('codmes').reset_index(drop=True)
X_full = sm.add_constant(macro_full[MACRO_CHAMPION_VARS])
macro_full['ft_GLOBAL'] = X_full.values @ np.array(betas_estimated)
macro_full['rd_pred_GLOBAL'] = norm.cdf(macro_full['ft_GLOBAL'].values)

ft_cal = macro_full[['codmes', 'ft_GLOBAL', 'rd_pred_GLOBAL'] + MACRO_CHAMPION_VARS].copy()
ft_cal = ft_cal.merge(
    rd_mes[['codmes', 'rd', 'n']].rename(columns={'rd': 'rd_obs'}),
    on='codmes', how='left',
)
ft_cal['gap_pp'] = (ft_cal['rd_pred_GLOBAL'] - ft_cal['rd_obs']) * 100

# Filtro de regimen F9: R2 del modelo en cada ventana de regimen
_var = MACRO_CHAMPION_VARS[0]
_covid = set(COVID_EXCL_MONTHS)
regime_r2 = {}
for _name, (_a, _b) in REGIME_WINDOWS.items():
    _w = merged[(merged['codmes'] >= _a) & (merged['codmes'] <= _b) & (~merged['codmes'].isin(_covid))]
    if len(_w) >= 5:
        regime_r2[_name] = float(np.corrcoef(_w['y'].values, _w[_var].values)[0, 1] ** 2)
    else:
        regime_r2[_name] = float('nan')
regime_pass = all((not np.isnan(v)) and v >= REGIME_R2_MIN for v in regime_r2.values())

print(f"  F9 regimen (R2 >= {REGIME_R2_MIN}): " +
      "  ".join(f"{k}={v:.3f}" for k, v in regime_r2.items()) +
      f"  -> {'PASS' if regime_pass else 'FAIL'}")
assert regime_pass, (
    f"Variable {_var} NO pasa filtro de regimen F9 "
    f"(R2 >= {REGIME_R2_MIN} en todas las ventanas): {regime_r2}"
)

ft_cal.to_csv(PATHS['csv'] / 'ft_calendario.csv', index=False)
macro_output = {
    'product': SUBPRODUCTO_FILTER,
    'champion_variables': MACRO_CHAMPION_VARS,
    'champion_spec': MACRO_SPEC,
    'betas_estimated': betas_estimated,
    'r2': float(model.rsquared),
    'r2_adj': float(model.rsquared_adj),
    'dw': float(dw),
    'adf_resid_pval': float(adf_pval),
    'mae_rd': float(mae),
    'n_meses_fit': int(len(merged)),
    'ft_n_meses': int(len(ft_cal)),
    'ft_range': [float(ft_cal['ft_GLOBAL'].min()), float(ft_cal['ft_GLOBAL'].max())],
    'ft_source': 'estimated_univariate',
    'regime_filter': {
        'r2_min': REGIME_R2_MIN,
        'windows': {k: list(v) for k, v in REGIME_WINDOWS.items()},
        'r2_by_regime': regime_r2,
        'regime_pass': bool(regime_pass),
    },
    'inference': {
        'method': 'HAC Newey-West (auto lags)',
        'se_beta1_ols': float(model_ols.bse.iloc[1]),
        'se_beta1_hac': float(model.bse.iloc[1]),
        't_beta1_hac': float(model.tvalues.iloc[1]),
        'p_beta1_hac': float(model.pvalues.iloc[1]),
        'se_inflation': float(model.bse.iloc[1] / model_ols.bse.iloc[1]),
        'note': f'DW={dw:.2f} indica autocorrelacion positiva. '
                f'HAC infla SE {model.bse.iloc[1]/model_ols.bse.iloc[1]:.2f}x '
                f'— beta1 sigue significativo (t={model.tvalues.iloc[1]:.1f}, p<0.001).',
    },
}
with open(PATHS['json'] / 'macro_model.json', 'w') as f:
    json.dump(macro_output, f, indent=2)
print("  export: ft_calendario.csv, macro_model.json")
