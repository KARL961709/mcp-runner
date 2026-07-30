# =============================================================================
# 05 — λ MLE BINOMIAL — Estimacion formal del partial adjustment factor
# =============================================================================
#
# Modelo:
#   pd_t(λ) = Φ((Φ⁻¹(LRA) - √ρ·λ·F_capped_t) / √(1-ρ))
#   L(λ) = Σ_t [ D_t·log(pd_t(λ)) + (N_t - D_t)·log(1 - pd_t(λ)) ]
#
# F_capped_t: Domötör & Illés (2025) centered systematic factor, capped P05/P95.
# β₀, β₁ FIJOS (ya estimados en 03_macro_ft). λ es el UNICO parametro libre.
# Ventana: meses con target maduro excl COVID.
# Test: H₀: λ=1.0 vs H₁: λ≠1.0 (Wald + LRT).
# =============================================================================

import json
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.optimize import minimize_scalar
from scipy.stats import norm, chi2

warnings.filterwarnings("ignore")

import sys

_PROJECT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_PROJECT / 'src'))

from config import (
    RANDOM_SEED, PATHS, SUBPRODUCTO_FILTER,
    COVID_EXCL_MONTHS, RD_HIST_INI, RD_HIST_FIN, f_center_meses,
    F_CAP_QUANTILE,
)

np.random.seed(RANDOM_SEED)

COVID_SET = set(COVID_EXCL_MONTHS)

# =============================================================================
# 1. Carga
# =============================================================================

print("=" * 70)
print(f"  05 — λ MLE BINOMIAL {SUBPRODUCTO_FILTER}")
print("=" * 70)

ft_df = pd.read_csv(PATHS['csv'] / 'ft_calendario.csv')
ft_df['codmes'] = ft_df['codmes'].astype(str)

with open(PATHS['json'] / 'vasicek_rho.json') as f:
    rho_json = json.load(f)
with open(PATHS['json'] / 'lra.json') as f:
    lra_json = json.load(f)

rho = rho_json['rho_final']
lra = lra_json['lra_global']

print(f"ρ = {rho:.6f}")
print(f"LRA = {lra*100:.4f}%")

# =============================================================================
# 2. F_capped (replicando logica de 06_pit_transformation)
# =============================================================================

z_lra = norm.ppf(lra)
sq_rho = np.sqrt(rho)
sq_1mrho = np.sqrt(1 - rho)

ft_df['F_raw'] = (z_lra - sq_1mrho * ft_df['ft_GLOBAL'].values) / sq_rho

# Centering: Dömötör & Illés (2025) eq(9)
# Misma ventana que el paso 06 (config.f_center_meses): si divergen, lambda se
# estima contra un F distinto del que se despliega.
_mc = set(f_center_meses(ft_df['codmes'].tolist()))
center_mask = ft_df['codmes'].isin(_mc)
F_center_mean = ft_df.loc[center_mask, 'F_raw'].mean()
ft_df['F_centered'] = ft_df['F_raw'] - F_center_mean

# Anti-extrapolation cap
lra_F_centered = ft_df.loc[center_mask, 'F_centered'].values
F_p_lo = float(np.quantile(lra_F_centered, 1 - F_CAP_QUANTILE))
F_p_hi = float(np.quantile(lra_F_centered, F_CAP_QUANTILE))
ft_df['F_capped'] = np.clip(ft_df['F_centered'].values, F_p_lo, F_p_hi)

n_capped = ((ft_df.loc[center_mask, 'F_centered'] < F_p_lo) |
             (ft_df.loc[center_mask, 'F_centered'] > F_p_hi)).sum()

print(f"F centering mean: {F_center_mean:.6f}")
print(f"F cap [{F_p_lo:.4f}, {F_p_hi:.4f}] (P{100*(1-F_CAP_QUANTILE):.0f}/P{100*F_CAP_QUANTILE:.0f})")
print(f"Centering window: {center_mask.sum()} meses, capped: {n_capped}")

# Verify consistency with 06 (if already run)
_pit_json_path = PATHS['json'] / 'pit_transformation.json'
if _pit_json_path.exists():
    with open(_pit_json_path) as f:
        pit_json = json.load(f)
    assert abs(F_p_lo - pit_json['f_cap_lo']) < 1e-6, \
        f"F_cap_lo mismatch: {F_p_lo} vs {pit_json['f_cap_lo']}"
    assert abs(F_p_hi - pit_json['f_cap_hi']) < 1e-6, \
        f"F_cap_hi mismatch: {F_p_hi} vs {pit_json['f_cap_hi']}"
    print("F_cap consistency check vs pit_transformation.json: PASS")
else:
    print("WARN: pit_transformation.json not found, skipping F_cap consistency check")

# =============================================================================
# 3. Merge rd_mensual + F_capped (excl COVID, meses maduros)
# =============================================================================

rd = pd.read_csv(PATHS['csv'] / 'rd_mensual.csv')
rd['codmes'] = rd['codmes'].astype(str)
rd = rd[~rd['codmes'].isin(COVID_SET)].copy()
rd = rd.sort_values('codmes').reset_index(drop=True)
rd = rd.merge(ft_df[['codmes', 'F_capped']], on='codmes', how='inner')

D = rd['defaults'].values.astype(float)
N = rd['n'].values.astype(float)
F = rd['F_capped'].values

print(f"\nMeses para MLE: {len(rd)}")
print(f"  range: {rd['codmes'].iloc[0]}–{rd['codmes'].iloc[-1]}")
print(f"  Total defaults: {D.sum():,.0f}, Total N: {N.sum():,.0f}")
print(f"  RD mean: {(D.sum()/N.sum())*100:.2f}%")
print(f"  F_capped range: [{F.min():.4f}, {F.max():.4f}]")

# =============================================================================
# 4. MLE functions
# =============================================================================


def pd_pit_agg(lam, lra_, rho_, F_capped):
    """Aggregate PD_PIT(λ) = Φ((Φ⁻¹(LRA) - √ρ·λ·F) / √(1-ρ))"""
    z = (norm.ppf(lra_) - np.sqrt(rho_) * lam * F_capped) / np.sqrt(1 - rho_)
    return norm.cdf(z)


def neg_log_likelihood(lam, D_, N_, lra_, rho_, F_capped):
    """Negative binomial log-likelihood (for minimization)."""
    p = pd_pit_agg(lam, lra_, rho_, F_capped)
    p = np.clip(p, 1e-10, 1 - 1e-10)
    ll = np.sum(D_ * np.log(p) + (N_ - D_) * np.log(1 - p))
    return -ll


def fisher_information(lam, D_, N_, lra_, rho_, F_capped, h=1e-5):
    """Numerical second derivative → Fisher info."""
    ll_c = -neg_log_likelihood(lam, D_, N_, lra_, rho_, F_capped)
    ll_p = -neg_log_likelihood(lam + h, D_, N_, lra_, rho_, F_capped)
    ll_m = -neg_log_likelihood(lam - h, D_, N_, lra_, rho_, F_capped)
    d2ll = (ll_p - 2 * ll_c + ll_m) / (h ** 2)
    return -d2ll


# =============================================================================
# 5. MLE estimation
# =============================================================================

print(f"\n{'=' * 70}")
print(f"  MLE OPTIMIZATION")
print(f"{'=' * 70}")

res = minimize_scalar(
    neg_log_likelihood, bounds=(0.01, 3.0), method='bounded',
    args=(D, N, lra, rho, F)
)
lam_mle = res.x
ll_mle = -res.fun

ll_lam1 = -neg_log_likelihood(1.0, D, N, lra, rho, F)
ll_lam0 = -neg_log_likelihood(0.001, D, N, lra, rho, F)

# Fisher → SE → CI
I_fisher = fisher_information(lam_mle, D, N, lra, rho, F)
if I_fisher > 0:
    se_lam = 1.0 / np.sqrt(I_fisher)
    ci_lo = lam_mle - 1.96 * se_lam
    ci_hi = lam_mle + 1.96 * se_lam
else:
    se_lam = ci_lo = ci_hi = np.nan

# Wald test: H₀: λ=1.0
if not np.isnan(se_lam) and se_lam > 0:
    z_wald = (lam_mle - 1.0) / se_lam
    p_wald = 2 * norm.sf(abs(z_wald))
else:
    z_wald = p_wald = np.nan

# LRT: 2(LL_MLE - LL_λ=1)
lrt_stat = 2 * (ll_mle - ll_lam1)
p_lrt = chi2.sf(lrt_stat, 1)

# Predictions at λ_MLE vs λ=1.0
pd_mle = pd_pit_agg(lam_mle, lra, rho, F)
pd_lam1 = pd_pit_agg(1.0, lra, rho, F)
rd_obs = D / N

mae_mle = np.mean(np.abs(rd_obs - pd_mle)) * 10000
mae_lam1 = np.mean(np.abs(rd_obs - pd_lam1)) * 10000
bias_mle = np.mean(pd_mle - rd_obs) * 10000
bias_lam1 = np.mean(pd_lam1 - rd_obs) * 10000

# AIC, BIC
aic_mle = -2 * ll_mle + 2 * 1
aic_lam1 = -2 * ll_lam1 + 2 * 0
bic_mle = -2 * ll_mle + np.log(len(D)) * 1
bic_lam1 = -2 * ll_lam1 + np.log(len(D)) * 0

# Profile likelihood grid
lam_grid = np.linspace(0.1, 2.0, 200)
ll_grid = [-neg_log_likelihood(l, D, N, lra, rho, F) for l in lam_grid]

print(f"\n  RESULTADOS:")
print(f"  λ_MLE = {lam_mle:.6f}")
print(f"  SE(λ) = {se_lam:.6f}")
print(f"  IC 95% = [{ci_lo:.4f}, {ci_hi:.4f}]")
print(f"  LL(λ_MLE) = {ll_mle:,.2f}")
print(f"  LL(λ=1.0) = {ll_lam1:,.2f}")
print(f"  LL(λ≈0)   = {ll_lam0:,.2f}")

print(f"\n  TEST H₀: λ=1.0:")
print(f"    Wald: z={z_wald:+.4f}, p={p_wald:.4e}")
print(f"    LRT:  χ²={lrt_stat:.4f}, p={p_lrt:.4e}")
reject = p_wald < 0.05 or p_lrt < 0.05
print(f"    → {'RECHAZA' if reject else 'NO RECHAZA'} H₀ al 5%")

print(f"\n  COMPARACION TRACKING ({len(D)}m):")
print(f"  {'':>20} {'λ_MLE':>12} {'λ=1.0':>12}")
print(f"  {'MAE (bp)':>20} {mae_mle:>12.1f} {mae_lam1:>12.1f}")
print(f"  {'Bias (bp)':>20} {bias_mle:>+12.1f} {bias_lam1:>+12.1f}")
print(f"  {'AIC':>20} {aic_mle:>12.2f} {aic_lam1:>12.2f}")
print(f"  {'BIC':>20} {bic_mle:>12.2f} {bic_lam1:>12.2f}")

print(f"\n  INTERPRETACION:")
if not reject:
    print(f"  λ=1.0 NO se rechaza → full model-based cycle justificado.")
    print(f"  No hay evidencia estadistica para dampening.")
else:
    print(f"  λ=1.0 RECHAZADO → evidencia de dampening.")
    print(f"  λ_MLE={lam_mle:.4f} es el estimador formal.")
    if ci_lo <= 1.0 <= ci_hi:
        print(f"  PERO: IC95% [{ci_lo:.4f}, {ci_hi:.4f}] contiene 1.0")
        print(f"  → resultado marginalmente significativo")

# Monthly detail
print(f"\n  DETALLE MENSUAL:")
print(f"  {'codmes':>7} {'n':>7} {'D':>5} {'RD_obs':>8} {'PD_λMLE':>8} {'PD_λ=1':>8} {'F_cap':>8}")
for i in range(len(rd)):
    print(f"  {rd['codmes'].iloc[i]:>7} {int(N[i]):>7} {int(D[i]):>5} "
          f"{rd_obs[i]*100:>7.2f}% {pd_mle[i]*100:>7.2f}% {pd_lam1[i]*100:>7.2f}% "
          f"{F[i]:>+7.4f}")

# =============================================================================
# 6. Export
# =============================================================================

monthly = []
for i in range(len(rd)):
    monthly.append({
        'codmes': rd['codmes'].iloc[i],
        'n': int(N[i]),
        'defaults': int(D[i]),
        'rd_obs': float(rd_obs[i]),
        'pd_pit_lam1': float(pd_lam1[i]),
        'pd_pit_lam_mle': float(pd_mle[i]),
        'F_capped': float(F[i]),
    })

output = {
    'product': SUBPRODUCTO_FILTER,
    'method': 'MLE binomial',
    'description': (
        'λ estimated by maximizing binomial log-likelihood L(λ) = '
        'Σ_t [D_t·log(pd_t(λ)) + (N_t-D_t)·log(1-pd_t(λ))]. '
        'β₀, β₁ fixed (probit MLE). λ is the only free parameter.'
    ),
    'window': f'{rd["codmes"].iloc[0]}-{rd["codmes"].iloc[-1]} excl COVID ({len(rd)}m)',
    'F_conversion': {
        'rho': float(rho),
        'lra': float(lra),
        'centering_mean': float(F_center_mean),
        'f_cap_lo': float(F_p_lo),
        'f_cap_hi': float(F_p_hi),
    },
    'lambda_mle': float(lam_mle),
    'se_lambda': float(se_lam),
    'ci_95_lo': float(ci_lo),
    'ci_95_hi': float(ci_hi),
    'll_mle': float(ll_mle),
    'll_lam1': float(ll_lam1),
    'll_lam0': float(ll_lam0),
    'wald_z': float(z_wald),
    'wald_p': float(p_wald),
    'lrt_chi2': float(lrt_stat),
    'lrt_p': float(p_lrt),
    'reject_h0_005': bool(reject),
    'mae_mle_bps': float(mae_mle),
    'mae_lam1_bps': float(mae_lam1),
    'bias_mle_bps': float(bias_mle),
    'bias_lam1_bps': float(bias_lam1),
    'aic_mle': float(aic_mle),
    'aic_lam1': float(aic_lam1),
    'bic_mle': float(bic_mle),
    'bic_lam1': float(bic_lam1),
    'n_months': len(D),
    'monthly': monthly,
    'profile_ll': {
        'lambda_grid': [float(l) for l in lam_grid],
        'll_grid': [float(l) for l in ll_grid],
    },
}

with open(PATHS['json'] / 'lambda_mle_binomial.json', 'w') as f:
    json.dump(output, f, indent=2, default=str)

print(f"\nExport: {PATHS['json'] / 'lambda_mle_binomial.json'}")

print(f"\n  DECISION:")
if reject:
    print(f"  λ_MLE = {lam_mle:.4f} — usar en config.py LAMBDA_PIT")
else:
    print(f"  λ = 1.0 — no se rechaza, mantener LAMBDA_PIT = 1.0")

print(f"\n{'=' * 70}")
print(f"  05 COMPLETADO — λ MLE {SUBPRODUCTO_FILTER}")
print(f"{'=' * 70}")
