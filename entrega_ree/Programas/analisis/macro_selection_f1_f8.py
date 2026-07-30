# =============================================================================
# MACRO SELECCION F1-F8 — Reenganche IBK
# =============================================================================
# Framework identico al usado para PP (macro_reselection_64m_combined.py):
#   F1: Relevancia economica
#   F2: Disponibilidad (≥60 obs, ≤10% NaN)
#   F3: Correlacion + signo (|r_p| ≥ 0.45, |r_s| ≥ 0.40)
#   F4: Causalidad de Granger (p < 0.10)
#   F5: Cointegracion / probit (R² ≥ 0.25, pHAC < 0.05, residuos I(0) ADF < 0.10, DW)  [vinculante]
#   F6: Buenos vs malos (t-test p < 0.10)
#   F7: Robustez temporal (sign stability ≥ 80%, split-sample)
#   F8: Estabilidad de regimen (R² ≥ 0.45 en subida/bajada/reciente)  [vinculante]
#   Holdout OOT: train ≤202210, test >202210
#   Bivariados: top10 × top10, VIF<5, LRT<0.05, ΔR²≥5%
# Nota: la estacionariedad se garantiza por cointegracion (residuos I(0)) en F5; NO
# se filtra el nivel del regresor (test inadecuado para relaciones cointegrantes,
# regresor I(1) con residuos I(0)). La estabilidad de regimen (F8) es el gate decisivo.
# =============================================================================

import json
import re
import warnings
from itertools import combinations
from pathlib import Path

import numpy as np
import pandas as pd
import statsmodels.api as sm
from statsmodels.tsa.stattools import adfuller, grangercausalitytests
from statsmodels.stats.stattools import durbin_watson
from scipy.stats import norm, pearsonr, spearmanr, ttest_ind, chi2

warnings.filterwarnings("ignore")
np.random.seed(202605)

PROJECT_ROOT = Path(__file__).resolve().parent.parent

# El outdir se resuelve por env, igual que el pipeline: con 'outputs' fijo este
# script leia la RD del vigente y escribia sobre el, aunque la corrida fuera
# sobre otra ventana.
import os  # noqa: E402
import sys  # noqa: E402

# Mismo criterio que config.PATHS: acepta REE_OUTDIR relativo o absoluto.
_o = os.environ.get('REE_OUTDIR', 'outputs')
_OUT = Path(_o).resolve() if Path(_o).is_absolute() else PROJECT_ROOT / _o
sys.path.insert(0, str(PROJECT_ROOT / 'src'))
# REGIME_WINDOWS / REGIME_R2_MIN se IMPORTAN de config: este script tenia su
# propia copia congelada en 202504 mientras config ya decia otra cosa. Una
# constante duplicada que deriva es exactamente el gate que no falla cuando debe.
from config import REGIME_WINDOWS, REGIME_R2_MIN  # noqa: E402

# =============================================================================
# 0. Umbrales F1-F8 (identicos a PP)
# =============================================================================

F2_MIN_OBS = 60
F2_MAX_NAN_PCT = 10.0
F3_ADF_MAX = 0.10
F4_MIN_CORR = 0.45
F4_MIN_CORR_SPEARMAN = 0.40
F5_MAX_PVAL = 0.10
F5_MAX_LAGS = 6
F6_MIN_R2 = 0.25
F6_PVAL_HAC = 0.05
F6_MIN_DW = 0.20
F6_ADF_RESID = 0.10
F7_TTEST_PVAL = 0.10
F7_MIN_PROPORTION = 0.30
F8_ROLLING_WINDOW = 36
F8_MIN_SIGN_STABLE = 0.80

HOLDOUT_CUTOFF = '202210'
COVID_MONTHS = set(f'2020{m:02d}' for m in range(1, 13))

# =============================================================================
# 1. RD REE
# =============================================================================

print("=" * 70)
print("  MACRO SELECCION F1-F8 — Reenganche IBK")
print("=" * 70)

rd_mes = pd.read_csv(_OUT / 'csv' / 'rd_mensual.csv')
rd_mes['codmes'] = rd_mes['codmes'].astype(str)
rd_mes = rd_mes[~rd_mes['codmes'].isin(COVID_MONTHS)].copy()
rd_mes = rd_mes.sort_values('codmes').reset_index(drop=True)

with open(_OUT / 'json' / 'vasicek_rho.json') as f:
    rho = json.load(f)['rho_final']
with open(_OUT / 'json' / 'lra.json') as f:
    lra = json.load(f)['lra_global']

print(f"RD REE: {len(rd_mes)} meses (excl COVID)")
print(f"  Rango: {rd_mes['codmes'].iloc[0]} — {rd_mes['codmes'].iloc[-1]}")
print(f"  RD media: {rd_mes['rd'].mean()*100:.2f}%")
print(f"  LRA: {lra*100:.4f}%, ρ: {rho:.6f}")

# Macro
from config import MACRO_PARQUET  # noqa: E402
macro = pd.read_parquet(MACRO_PARQUET).reset_index()
macro['codmes'] = macro['codmes'].astype(float).astype(int).astype(str)

merged = rd_mes[['codmes', 'rd', 'n']].merge(macro, on='codmes', how='inner')
merged = merged.sort_values('codmes').reset_index(drop=True)
rd = merged['rd'].values
z_rd = norm.ppf(np.clip(rd, 1e-6, 1 - 1e-6))
codmeses = merged['codmes'].values
n_meses = len(rd)

all_macro_cols = [c for c in macro.columns if c != 'codmes']
print(f"  Macro variables: {len(all_macro_cols)}")
print(f"  Meses overlap: {n_meses}")

train_mask = merged['codmes'] <= HOLDOUT_CUTOFF
test_mask = merged['codmes'] > HOLDOUT_CUTOFF
n_train = train_mask.sum()
n_test = test_mask.sum()
print(f"  Train: {n_train}m (≤{HOLDOUT_CUTOFF}), Test: {n_test}m (>{HOLDOUT_CUTOFF})")

# =============================================================================
# SIGNO ESPERADO (identico a PP)
# =============================================================================

EXPECTED_SIGNS = {
    'IPC': +1, 'Inflacion': +1,
    'Tasa_interbancaria': +1, 'Tasa_referencia': +1,
    'Tasa_TC': +1, 'Tasa_tarjeta': +1,
    'Tasa_consumo': +1, 'Tasa_prestamo': +1,
    'Tasa_desempleo': +1, 'Desempleo': +1,
    'TAMN': +1, 'TAMEX': +1, 'TIPMN': +1, 'TIPMEX': +1,
    'Spread_TAMN': -1,
    'Credito_consumo_crec': +1,
    'PBI': -1, 'Demanda': -1, 'Manufactura': -1, 'Comercio': -1,
    'Empleo': -1, 'PEA': -1, 'Ingreso': -1, 'Masa_salarial': -1,
    'RMV': -1, 'Produccion': -1,
    'TC_': +1, 'Coef_dolarizacion': +1, 'Dolarizacion': +1,
    'Exp_PBI': -1, 'Exp_TC': +1, 'Exp_inflacion': +1,
    'EMBIG': +1, 'IGBVL': -1,
    'Liquidez': -1, 'Electricidad': -1,
}

_STRIP_RE = re.compile(
    r'_(lag\d+|ma\d+|mom\d+|dev_ma\d+|accel|shock|z\d+|var_\d+m|delta\d+|var_\d+m_delta\d+)'
)


def infer_sign(var_name):
    root = _STRIP_RE.sub('', var_name)
    for key, sign in EXPECTED_SIGNS.items():
        if root.startswith(key):
            return sign
    return 0


# =============================================================================
# F1 — Relevancia economica
# =============================================================================

VALID_PREFIXES = [
    'IPC_', 'Tasa_', 'TAMN', 'TAMEX', 'TIPMN', 'TIPMEX', 'Spread_',
    'PBI_', 'Demanda_', 'Manufactura_', 'Comercio_', 'Cemento_', 'Construccion_',
    'Tasa_desempleo', 'Desempleo_', 'Empleo_', 'PEA_', 'Ingreso_', 'RMV_',
    'TC_', 'Exp_', 'Credito_', 'EMBIG_', 'IGBVL_',
    'Coef_dolarizacion', 'Liquidez_', 'Morosidad_',
    'Produccion_', 'Inflacion_', 'Dolarizacion_',
    'Electricidad_', 'Consumo_', 'Inversion_', 'Masa_salarial',
    'Depositos_', 'Circulante', 'Emision_', 'Cuasidinero',
    'Diferencial_', 'Ratio_credito', 'Vehiculos_',
]
EXCL_PREFIXES = ['Cobre_', 'Oro_', 'Terminos_intercambio']

f1_pass = []
for col in all_macro_cols:
    root = _STRIP_RE.sub('', col)
    excluded = any(root.startswith(p) for p in EXCL_PREFIXES)
    relevant = any(root.startswith(p) for p in VALID_PREFIXES)
    if relevant and not excluded:
        f1_pass.append(col)

print(f"\nF1 PASS: {len(f1_pass)} / {len(all_macro_cols)}")

# =============================================================================
# F2 — Disponibilidad
# =============================================================================

f2_pass = []
for col in f1_pass:
    if col not in merged.columns:
        continue
    vals = merged[col].values
    n_valid = int(np.sum(~np.isnan(vals)))
    nan_pct = float(np.mean(np.isnan(vals)) * 100)
    if n_valid >= F2_MIN_OBS and nan_pct <= F2_MAX_NAN_PCT:
        f2_pass.append(col)

print(f"F2 PASS: {len(f2_pass)}")

# =============================================================================
# Estacionariedad -> por cointegracion (NO se filtra el nivel del regresor)
# =============================================================================
# El test de estacionariedad sobre el nivel del regresor es inadecuado para
# relaciones cointegrantes (regresor I(1) con residuos I(0)). La condicion
# vinculante de estacionariedad se aplica como cointegracion (residuos I(0)) en el
# paso probit (F5). Se conserva el ADF de nivel solo como reporte, sin filtrar.
f3_data = {}
for col in f2_pass:
    vals = merged[col].dropna().values
    if len(vals) >= 20:
        try:
            f3_data[col] = float(adfuller(vals, maxlag=6)[1])
        except Exception:
            f3_data[col] = 1.0
f3_pass = list(f2_pass)

# =============================================================================
# F4 — Correlacion + signo
# =============================================================================

f4_pass = []
f4_data = {}
for col in f3_pass:
    vals = merged[col].values
    mask = ~np.isnan(vals)
    if mask.sum() < 20:
        continue
    v, r_v = vals[mask], rd[mask]
    corr_p, _ = pearsonr(v, r_v)
    corr_s, _ = spearmanr(v, r_v)
    exp_sign = infer_sign(col)
    actual_sign = 1 if corr_p > 0 else -1
    sign_ok = (exp_sign == 0) or (exp_sign == actual_sign)

    f4_data[col] = {
        'corr_p': float(corr_p), 'corr_s': float(corr_s),
        'exp_sign': exp_sign, 'sign_ok': sign_ok,
    }

    if abs(corr_p) >= F4_MIN_CORR and abs(corr_s) >= F4_MIN_CORR_SPEARMAN and sign_ok:
        f4_pass.append(col)

print(f"F4 PASS: {len(f4_pass)}")

# =============================================================================
# F5 — Granger
# =============================================================================

f5_pass = []
f5_data = {}
for col in f4_pass:
    vals = merged[col].values
    s_macro = pd.Series(vals).interpolate(limit=3)
    s_rd = pd.Series(rd)
    both = s_macro.notna() & s_rd.notna()
    if both.sum() < 30:
        continue
    fi = both.idxmax()
    li = both[::-1].idxmax()
    block = pd.DataFrame({
        'rd': s_rd.iloc[fi:li + 1].values,
        'macro': s_macro.iloc[fi:li + 1].values,
    }).dropna()
    if len(block) < 20:
        continue
    max_lag = min(F5_MAX_LAGS, len(block) // 5)
    if max_lag < 1:
        continue
    try:
        gc = grangercausalitytests(block[['rd', 'macro']].values, maxlag=max_lag, verbose=False)
        pvals = {k: float(gc[k][0]['ssr_ftest'][1]) for k in range(1, max_lag + 1)}
        best_lag = min(pvals, key=pvals.get)
        best_p = pvals[best_lag]

        gc_r = grangercausalitytests(block[['macro', 'rd']].values, maxlag=max_lag, verbose=False)
        rev_p = min(float(gc_r[k][0]['ssr_ftest'][1]) for k in range(1, max_lag + 1))
        uni = best_p < F5_MAX_PVAL and rev_p >= F5_MAX_PVAL
    except:
        best_p, best_lag, uni, rev_p = 1.0, None, None, 1.0

    f5_data[col] = {'p': best_p, 'lag': best_lag, 'uni': uni, 'rev_p': rev_p}
    if best_p < F5_MAX_PVAL:
        f5_pass.append(col)

print(f"F5 PASS: {len(f5_pass)}")

# =============================================================================
# F6 — Probit model
# =============================================================================

f6_pass = []
f6_data = {}
for col in f5_pass:
    vals = merged[col].values
    mask = ~np.isnan(vals)
    if mask.sum() < 20:
        continue
    V = vals[mask]
    z_fit = z_rd[mask]

    try:
        X = sm.add_constant(V)
        model = sm.OLS(z_fit, X).fit(cov_type='HAC', cov_kwds={'maxlags': None})
        r2 = float(model.rsquared)
        r2_adj = float(model.rsquared_adj)
        b0, b1 = float(model.params[0]), float(model.params[1])
        p_hac = float(model.pvalues[1])
        dw = float(durbin_watson(model.resid))
        adf_r = float(adfuller(model.resid, maxlag=4)[1])
        rd_pred = norm.cdf(model.fittedvalues)
        mae = float(np.mean(np.abs(rd[mask] - rd_pred)))

        passed = r2 >= F6_MIN_R2 and p_hac < F6_PVAL_HAC and adf_r < F6_ADF_RESID and dw > F6_MIN_DW

        fail_reasons = []
        if r2 < F6_MIN_R2:
            fail_reasons.append(f'R2={r2:.3f}')
        if p_hac >= F6_PVAL_HAC:
            fail_reasons.append(f'pHAC={p_hac:.2e}')
        if adf_r >= F6_ADF_RESID:
            fail_reasons.append(f'ADF_resid={adf_r:.3f}')
        if dw < F6_MIN_DW:
            fail_reasons.append(f'DW={dw:.3f}')

        f6_data[col] = {
            'r2': r2, 'r2_adj': r2_adj, 'b0': b0, 'b1': b1,
            'p_hac': p_hac, 'dw': dw, 'adf_r': adf_r, 'mae': mae,
            'pass': passed, 'fail': fail_reasons,
        }
        if passed:
            f6_pass.append(col)
    except:
        pass

print(f"F6 PASS: {len(f6_pass)}")

notable_f6_fail = []
for col in f5_pass:
    if col not in f6_pass and col in f6_data:
        d = f6_data[col]
        if d['r2'] >= 0.20:
            notable_f6_fail.append((col, d))
if notable_f6_fail:
    print(f"\n  Notable F6 near-misses:")
    for col, d in sorted(notable_f6_fail, key=lambda x: -x[1]['r2'])[:10]:
        print(f"    {col:50s} R2={d['r2']:.3f} DW={d['dw']:.3f} ADF_r={d['adf_r']:.3f} FAIL: {d['fail']}")

# =============================================================================
# F7 — Buenos vs malos
# =============================================================================

rd_mean = rd.mean()
good_mask = rd < rd_mean
bad_mask = rd >= rd_mean
prop_ok = (good_mask.mean() >= F7_MIN_PROPORTION and bad_mask.mean() >= F7_MIN_PROPORTION)

f7_pass = []
f7_data = {}
for col in f6_pass:
    vals = merged[col].values
    mask = ~np.isnan(vals)
    v_good = vals[mask & good_mask]
    v_bad = vals[mask & bad_mask]
    if len(v_good) < 5 or len(v_bad) < 5:
        continue
    t_stat, t_pval = ttest_ind(v_good, v_bad, equal_var=False)
    exp_sign = infer_sign(col)
    if exp_sign > 0:
        dir_ok = np.mean(v_bad) > np.mean(v_good)
    elif exp_sign < 0:
        dir_ok = np.mean(v_bad) < np.mean(v_good)
    else:
        dir_ok = True

    passed = t_pval < F7_TTEST_PVAL and prop_ok and dir_ok
    f7_data[col] = {'t_pval': float(t_pval), 'dir_ok': dir_ok}
    if passed:
        f7_pass.append(col)

print(f"F7 PASS: {len(f7_pass)}")

# =============================================================================
# F8 — Robustez temporal
# =============================================================================

f8_pass = []
f8_data = {}
for col in f7_pass:
    vals = merged[col].values
    mask = ~np.isnan(vals)
    valid_idx = np.where(mask)[0]
    if len(valid_idx) < F8_ROLLING_WINDOW + 5:
        continue

    n_win = len(valid_idx) - F8_ROLLING_WINDOW + 1
    rolling_signs = []
    rolling_r2s = []
    rolling_betas = []

    for start in range(n_win):
        idx = valid_idx[start:start + F8_ROLLING_WINDOW]
        V_w = vals[idx]
        z_w = z_rd[idx]
        try:
            X_w = sm.add_constant(V_w)
            fit_w = sm.OLS(z_w, X_w).fit()
            b1 = float(fit_w.params[1])
            rolling_betas.append(b1)
            rolling_signs.append(1 if b1 > 0 else -1)
            rolling_r2s.append(float(fit_w.rsquared))
        except:
            pass

    if len(rolling_betas) < 5:
        continue

    exp_sign = infer_sign(col)
    if exp_sign != 0:
        sign_pct = sum(1 for s in rolling_signs if s == exp_sign) / len(rolling_signs)
    else:
        majority = 1 if sum(rolling_signs) > 0 else -1
        sign_pct = sum(1 for s in rolling_signs if s == majority) / len(rolling_signs)

    mid = len(valid_idx) // 2
    try:
        fit_a = sm.OLS(z_rd[valid_idx[:mid]], sm.add_constant(vals[valid_idx[:mid]])).fit()
        fit_b = sm.OLS(z_rd[valid_idx[mid:]], sm.add_constant(vals[valid_idx[mid:]])).fit()
        b1_a, b1_b = float(fit_a.params[1]), float(fit_b.params[1])
        split_ok = (b1_a > 0) == (b1_b > 0)
        beta_ratio = abs(b1_a / b1_b) if b1_b != 0 else np.inf
    except:
        split_ok = False
        b1_a = b1_b = np.nan
        beta_ratio = np.inf

    passed = sign_pct >= F8_MIN_SIGN_STABLE and split_ok and beta_ratio < 10

    f8_data[col] = {
        'sign_pct': sign_pct, 'r2_roll_mean': np.mean(rolling_r2s),
        'r2_roll_min': np.min(rolling_r2s),
        'split_ok': split_ok, 'b1_a': b1_a, 'b1_b': b1_b,
        'n_win': len(rolling_betas),
    }
    if passed:
        f8_pass.append(col)

print(f"F8 robustez PASS: {len(f8_pass)}")

# =============================================================================
# F8 (gate decisivo) — Estabilidad de regimen
# =============================================================================
# R2 >= 0.45 en cada ventana de mora (full / subida / bajada / reciente, excl COVID).
# Es el filtro vinculante final: descarta variables cuyo poder explicativo colapsa
# en el regimen reciente, que es el relevante para la proyeccion forward (Z2).
# REGIME_WINDOWS / REGIME_R2_MIN vienen de config (import arriba). No redefinir.

f9_pass = []
f9_data = {}
for col in f8_pass:
    vals = merged[col].values
    r2s = {}
    for _name, (_a, _b) in REGIME_WINDOWS.items():
        w = (codmeses >= _a) & (codmeses <= _b) & (~np.isnan(vals))
        if w.sum() > 3:
            r2s[_name] = float(np.corrcoef(z_rd[w], vals[w])[0, 1] ** 2)
    f9_data[col] = r2s
    if all(r2s.get(k, 0.0) >= REGIME_R2_MIN for k in REGIME_WINDOWS):
        f9_pass.append(col)

print(f"F8 regimen PASS: {len(f9_pass)} (R2>=0.45 en las 4 ventanas)")

# =============================================================================
# HOLDOUT OOT EVALUATION
# =============================================================================

print(f"\n{'=' * 70}")
print("  HOLDOUT OOT EVALUATION")
print(f"{'=' * 70}")

final = f9_pass if f9_pass else (f8_pass if f8_pass else f7_pass)
holdout_results = {}

for col in final:
    vals = merged[col].values
    mask_all = ~np.isnan(vals)

    tr = train_mask.values & mask_all
    te = test_mask.values & mask_all

    if tr.sum() < 20 or te.sum() < 5:
        continue

    X_tr = sm.add_constant(vals[tr])
    z_tr = z_rd[tr]
    X_te = sm.add_constant(vals[te])
    z_te = z_rd[te]
    rd_te = rd[te]

    try:
        model_tr = sm.OLS(z_tr, X_tr).fit()
        z_pred_te = model_tr.predict(X_te)
        rd_pred_te = norm.cdf(z_pred_te)

        mae_oot = float(np.mean(np.abs(rd_te - rd_pred_te)))
        bias_oot = float(np.mean(rd_pred_te - rd_te))
        ss_res = np.sum((z_te - z_pred_te) ** 2)
        ss_tot = np.sum((z_te - z_te.mean()) ** 2)
        r2_oot = float(1 - ss_res / ss_tot) if ss_tot > 0 else 0

        X_full = sm.add_constant(vals[mask_all])
        model_full = sm.OLS(z_rd[mask_all], X_full).fit(cov_type='HAC', cov_kwds={'maxlags': None})

        holdout_results[col] = {
            'mae_oot': mae_oot,
            'mae_oot_bps': mae_oot * 10000,
            'bias_oot': bias_oot,
            'bias_oot_bps': bias_oot * 10000,
            'r2_oot': r2_oot,
            'r2_full': float(model_full.rsquared),
            'b0_full': float(model_full.params[0]),
            'b1_full': float(model_full.params[1]),
            'p_hac_full': float(model_full.pvalues[1]),
            'dw_full': float(durbin_watson(model_full.resid)),
            'adf_resid_full': float(adfuller(model_full.resid, maxlag=4)[1]),
            'n_train': int(tr.sum()),
            'n_test': int(te.sum()),
        }
    except Exception as e:
        holdout_results[col] = {'error': str(e)}

ranked = sorted(
    [(col, h) for col, h in holdout_results.items() if 'mae_oot' in h],
    key=lambda x: x[1]['mae_oot']
)

print(f"\n{'Rank':<5} {'Variable':<50} {'R²_full':<8} {'R²_OOT':<8} {'MAE_OOT':<10} "
      f"{'Bias_OOT':<10} {'DW':<6} {'ADF_r':<8} {'Granger':<8} {'Sign%':<6}")
print("-" * 160)
for i, (col, h) in enumerate(ranked):
    f5d = f5_data.get(col, {})
    f8d = f8_data.get(col, {})
    uni_str = 'UNI' if f5d.get('uni') else 'BI' if f5d.get('uni') is False else '?'
    print(f"{i + 1:<5} {col:<50} {h['r2_full']:<8.4f} {h['r2_oot']:<8.4f} "
          f"{h['mae_oot_bps']:<10.1f} {h['bias_oot_bps']:+<10.1f} "
          f"{h['dw_full']:<6.3f} {h['adf_resid_full']:<8.4f} "
          f"{f5d.get('p', 0):<8.4f} {f8d.get('sign_pct', 0):<6.0%}")

# =============================================================================
# BIVARIADOS (top 10 x top 10)
# =============================================================================

print(f"\n{'=' * 70}")
print("  EVALUACION BIVARIADA")
print(f"{'=' * 70}")

top_uni = [col for col, _ in ranked[:min(10, len(ranked))]]
best_uni_r2 = ranked[0][1]['r2_full'] if ranked else 0

bi_results = []
for v1, v2 in combinations(top_uni, 2):
    vals1 = merged[v1].values
    vals2 = merged[v2].values
    mask_bi = ~np.isnan(vals1) & ~np.isnan(vals2)

    if mask_bi.sum() < 30:
        continue

    z_bi = z_rd[mask_bi]
    X_bi = np.column_stack([np.ones(mask_bi.sum()), vals1[mask_bi], vals2[mask_bi]])

    try:
        model_bi = sm.OLS(z_bi, X_bi).fit(cov_type='HAC', cov_kwds={'maxlags': None})
        r2_bi = float(model_bi.rsquared)
        r2_adj_bi = float(model_bi.rsquared_adj)

        corr12 = float(np.corrcoef(vals1[mask_bi], vals2[mask_bi])[0, 1])
        vif_val = 1 / (1 - corr12 ** 2)

        b1, b2 = float(model_bi.params[1]), float(model_bi.params[2])
        s1_ok = infer_sign(v1) == 0 or (b1 > 0) == (infer_sign(v1) > 0)
        s2_ok = infer_sign(v2) == 0 or (b2 > 0) == (infer_sign(v2) > 0)

        ll_full = model_bi.llf
        model_r = sm.OLS(z_bi, sm.add_constant(vals1[mask_bi])).fit()
        ll_restr = model_r.llf
        lrt_stat = 2 * (ll_full - ll_restr)
        lrt_p = float(chi2.sf(lrt_stat, 1))

        tr_bi = train_mask.values & mask_bi
        te_bi = test_mask.values & mask_bi
        if tr_bi.sum() >= 20 and te_bi.sum() >= 5:
            X_tr_bi = np.column_stack([np.ones(tr_bi.sum()), vals1[tr_bi], vals2[tr_bi]])
            model_tr_bi = sm.OLS(z_rd[tr_bi], X_tr_bi).fit()
            X_te_bi = np.column_stack([np.ones(te_bi.sum()), vals1[te_bi], vals2[te_bi]])
            z_pred_bi = model_tr_bi.predict(X_te_bi)
            mae_oot_bi = float(np.mean(np.abs(rd[te_bi] - norm.cdf(z_pred_bi))))
        else:
            mae_oot_bi = np.nan

        r2_improve = (r2_bi - best_uni_r2) / best_uni_r2

        bi_results.append({
            'v1': v1, 'v2': v2,
            'r2': r2_bi, 'r2_adj': r2_adj_bi,
            'r2_improve': r2_improve,
            'b0': float(model_bi.params[0]),
            'b1': b1, 'b2': b2,
            'p1_hac': float(model_bi.pvalues[1]),
            'p2_hac': float(model_bi.pvalues[2]),
            'vif': round(vif_val, 2),
            'corr12': round(corr12, 3),
            'lrt_p': lrt_p,
            's1_ok': s1_ok, 's2_ok': s2_ok,
            'mae_oot': mae_oot_bi,
            'mae_oot_bps': mae_oot_bi * 10000 if not np.isnan(mae_oot_bi) else np.nan,
            'pass': vif_val < 5 and lrt_p < 0.05 and r2_improve >= 0.05 and s1_ok and s2_ok,
        })
    except:
        pass

bi_valid = [b for b in bi_results if b['pass']]
bi_valid.sort(key=lambda x: x['r2'], reverse=True)

print(f"Pares evaluados: {len(bi_results)}")
print(f"Bivariados validos: {len(bi_valid)}")

if bi_valid:
    print(f"\n{'V1':<40} {'V2':<40} {'R²':<7} {'ΔR²%':<7} {'VIF':<6} "
          f"{'LRT_p':<8} {'MAE_OOT':<10}")
    print("-" * 160)
    for b in bi_valid[:15]:
        mae_str = f"{b['mae_oot_bps']:.1f}" if not np.isnan(b['mae_oot_bps']) else "N/A"
        print(f"{b['v1']:<40} {b['v2']:<40} {b['r2']:<7.4f} "
              f"{b['r2_improve']*100:+<6.1f}% {b['vif']:<6.2f} "
              f"{b['lrt_p']:<8.4f} {mae_str:<10}")

bi_by_holdout = sorted(
    [b for b in bi_results if not np.isnan(b.get('mae_oot', np.nan))],
    key=lambda x: x['mae_oot']
)
if bi_by_holdout:
    print(f"\nTop 10 bivariados por MAE holdout:")
    for i, b in enumerate(bi_by_holdout[:10]):
        v_str = "✓" if b['pass'] else "✗"
        print(f"  {i+1:2d}. {b['v1']:<40} + {b['v2']:<40} "
              f"MAE={b['mae_oot_bps']:.1f}bp R²={b['r2']:.4f} {v_str}")

# =============================================================================
# COMPARISON: Current config vs new ranking
# =============================================================================

print(f"\n{'=' * 70}")
print("  COMPARISON: CURRENT CONFIG vs NEW")
print(f"{'=' * 70}")

current = 'IPC_Lima_var_12m_lag5_ma6'
if current in holdout_results:
    h = holdout_results[current]
    print(f"Current config ({current}):")
    print(f"  R²_full={h['r2_full']:.4f}, R²_OOT={h['r2_oot']:.4f}, "
          f"MAE_OOT={h['mae_oot_bps']:.1f}bp, Bias={h['bias_oot_bps']:+.1f}bp")
    print(f"  β₀={h['b0_full']:.6f}, β₁={h['b1_full']:.6f}")
    print(f"  DW={h['dw_full']:.3f}, ADF_resid={h['adf_resid_full']:.4f}")
else:
    for label, lst in [('F1', f1_pass), ('F2', f2_pass), ('F3', f3_pass),
                       ('F4', f4_pass), ('F5', f5_pass), ('F6', f6_pass),
                       ('F7', f7_pass), ('F8', f8_pass)]:
        if current not in lst:
            print(f"Current config ({current}) FAILED at {label}")
            if current in f3_data:
                print(f"  ADF p={f3_data[current]:.4f}")
            if current in f4_data:
                d = f4_data[current]
                print(f"  corr_p={d['corr_p']:.4f} corr_s={d['corr_s']:.4f} sign_ok={d['sign_ok']}")
            if current in f6_data:
                d = f6_data[current]
                print(f"  R²={d['r2']:.4f} DW={d['dw']:.3f} ADF_r={d['adf_r']:.4f} FAIL: {d['fail']}")
            break

if ranked:
    new_champ = ranked[0]
    print(f"\nNew champion by holdout ({new_champ[0]}):")
    h = new_champ[1]
    print(f"  R²_full={h['r2_full']:.4f}, R²_OOT={h['r2_oot']:.4f}, "
          f"MAE_OOT={h['mae_oot_bps']:.1f}bp, Bias={h['bias_oot_bps']:+.1f}bp")
    print(f"  β₀={h['b0_full']:.6f}, β₁={h['b1_full']:.6f}")

# =============================================================================
# PERSIST
# =============================================================================

output = {
    'framework': 'F1-F8 + Holdout OOT',
    'universo': 'Reenganche IBK',
    'n_meses': n_meses,
    'rango': f'{codmeses[0]}-{codmeses[-1]}',
    'holdout_cutoff': HOLDOUT_CUTOFF,
    'n_train': int(n_train),
    'n_test': int(n_test),
    'lra': lra,
    'rho': rho,
    'funnel': {
        'total': len(all_macro_cols),
        'F1_relevancia': len(f1_pass),
        'F2_disponibilidad': len(f2_pass),
        'F3_correlacion_signo': len(f4_pass),
        'F4_granger': len(f5_pass),
        'F5_cointegracion': len(f6_pass),
        'F6_buenos_malos': len(f7_pass),
        'F7_robustez': len(f8_pass),
        'F8_regimen': len(f9_pass),
    },
    'regimen': {'r2_min': REGIME_R2_MIN, 'windows': REGIME_WINDOWS, 'r2_by_var': f9_data},
    'univariate_ranking': [
        {**holdout_results[col], 'variable': col,
         'granger_p': f5_data.get(col, {}).get('p'),
         'granger_lag': f5_data.get(col, {}).get('lag'),
         'uni': f5_data.get(col, {}).get('uni'),
         'sign_pct': f8_data.get(col, {}).get('sign_pct'),
         'regime_r2': f9_data.get(col),
         }
        for col, _ in ranked
    ],
    'bivariados_validos': len(bi_valid),
    'bivariados_ranking': bi_valid[:10],
    'bivariados_by_holdout': [
        {k: v for k, v in b.items()} for b in bi_by_holdout[:10]
    ] if bi_by_holdout else [],
}

out_path = _OUT / 'json' / 'macro_selection_f1_f8.json'
out_path.parent.mkdir(parents=True, exist_ok=True)
with open(out_path, 'w') as f:
    json.dump(output, f, indent=2, default=str)
print(f"\nPersistido: {out_path}")

print(f"\n{'=' * 70}")
print("  DONE — MACRO SELECCION F1-F8 Reenganche IBK")
print(f"{'=' * 70}")
