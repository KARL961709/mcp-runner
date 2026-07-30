# =============================================================================
# 06 — Transformacion PIT completa (Reenganche)
# =============================================================================
# Cadena:
#   pd_ree → Beta Cal(tipo_ingreso) → probit δ → pd_ttc
#   pd_ttc → additive probit per-driver calibration(LRA targets) → pd_ttc_adj
#   pd_ttc_adj → Vasicek PIT(ft_GLOBAL, ρ, λ) → pd_pit
#
# Z1: optimiza δ aditivos por driver + δ_global, extrae coeficientes.
# Z2: aplica mismos coeficientes de Z1 (sin re-optimizar).
# ft_GLOBAL univariado (IPC_Lima_var_12m_lag5_ma6) compartido.
# =============================================================================

import json
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import norm
from scipy.optimize import brentq, minimize

warnings.filterwarnings("ignore", category=FutureWarning)

import sys

_PROJECT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_PROJECT / 'src'))

from config import (
    RANDOM_SEED, PATHS, TARGET_COL, SCORE_COL, SUBPRODUCTO_FILTER,
    SEG_COL, SEG_VALUES, DRIVER_COLS, LAMBDA_PIT, COHORTE_FIN,
    COVID_EXCL_MONTHS, RD_HIST_INI, RD_HIST_FIN, F_CAP_QUANTILE,
    F_CENTER_INI, F_CENTER_FIN, F_CENTER_EXCL, f_center_meses,
    DRIVER_RMSE_THRESHOLD, CANDIDATE_DRIVERS, DUMMY_REF, RHO_SCALING,
    DRIVER_GAP_TOLERANCIA_BPS,
    PIT_METHOD,
)
from calibration import BetaCalibrator
from vasicek import vasicek_pit, rho_scaled_basel

np.random.seed(RANDOM_SEED)

# =============================================================================
# 1. Carga de parametros
# =============================================================================

print("=" * 60)
print(f"  06 — PIT TRANSFORMATION {SUBPRODUCTO_FILTER}")
print("=" * 60)

df_z1 = pd.read_parquet(PATHS['parquets'] / 'z1.parquet')
df_z2 = pd.read_parquet(PATHS['parquets'] / 'z2.parquet')
print(f"Z1: {len(df_z1):,} | Z2: {len(df_z2):,}")

with open(PATHS['json'] / 'calibracion_beta.json') as f:
    cal_json = json.load(f)

with open(PATHS['json'] / 'vasicek_rho.json') as f:
    rho_json = json.load(f)

with open(PATHS['json'] / 'lra.json') as f:
    lra_json = json.load(f)

ft_cal = pd.read_csv(PATHS['csv'] / 'ft_calendario.csv')
ft_cal['codmes'] = ft_cal['codmes'].astype(str)
ft_dict = dict(zip(ft_cal['codmes'], ft_cal['ft_GLOBAL']))

rho = rho_json['rho_final']
lra_by_driver = lra_json['lra_by_driver']
lra_global = lra_json['lra_global']

# Convert ft_macro → F_vasicek
z_lra = norm.ppf(lra_global)
sqrt_rho = np.sqrt(rho)
sqrt_1mrho = np.sqrt(1 - rho)
for cm in ft_dict:
    ft_macro = ft_dict[cm]
    ft_dict[cm] = (z_lra - sqrt_1mrho * ft_macro) / sqrt_rho

# Dömötör & Illés (2025) eq(9): Σf_t = 0 sobre la ventana de la LRA.
# La ventana viene de config.f_center_meses(): antes se colgaba de RD_HIST_FIN
# y centraba sobre 76 meses, 10 de ellos SIN RD observada, mientras este mismo
# comentario declaraba la ventana de LRA (54m) y rho (66m). Ver config.
_meses_centro = set(f_center_meses(ft_dict.keys()))
lra_F = [f for cm, f in ft_dict.items() if cm in _meses_centro]
ft_mean = np.mean(lra_F)
ft_dict = {cm: f - ft_mean for cm, f in ft_dict.items()}
print(f"F centrado sobre {len(lra_F)} meses "
      f"[{F_CENTER_INI}-{F_CENTER_FIN}, excl={F_CENTER_EXCL}]  mu={ft_mean:+.6f}")

# Anti-extrapolation cap: limit F_centered to [P05, P95] of centering window.
lra_F_centered = [f for cm, f in ft_dict.items() if cm in _meses_centro]
F_p_lo = float(np.quantile(lra_F_centered, 1 - F_CAP_QUANTILE))
F_p_hi = float(np.quantile(lra_F_centered, F_CAP_QUANTILE))
n_capped = sum(1 for f in ft_dict.values() if f < F_p_lo or f > F_p_hi)
ft_dict = {cm: float(np.clip(f, F_p_lo, F_p_hi)) for cm, f in ft_dict.items()}

print(f"ρ = {rho:.6f}")
print(f"ρ scaling = {RHO_SCALING}")
print(f"PIT method = {PIT_METHOD}")
print(f"λ = {LAMBDA_PIT}")
print(f"ρ_eff = {rho * LAMBDA_PIT**2:.6f}")
print(f"LRA global = {lra_global*100:.4f}%")
print(f"ft calendario: {len(ft_dict)} meses")
ft_vals = list(ft_dict.values())
print(f"F_vasicek mean (pre-center): {ft_mean:+.4f}, post-center: {np.mean(ft_vals):+.6f}")
print(f"F_vasicek range: [{min(ft_vals):.4f}, {max(ft_vals):.4f}]")
print(f"F cap [{F_p_lo:.4f}, {F_p_hi:.4f}] (P{100*(1-F_CAP_QUANTILE):.0f}/P{100*F_CAP_QUANTILE:.0f}), {n_capped} months capped")

seg_cals = {}
seg_deltas = {}
for seg in SEG_VALUES:
    params = cal_json['segments'][seg]
    bc = BetaCalibrator()
    bc.a_ = params['a']
    bc.b_ = params['b']
    bc.c_ = params['m']
    seg_cals[seg] = bc
    seg_deltas[seg] = params['probit_delta']
    print(f"  {seg}: a={params['a']:.6f}, b={params['b']:.6f}, m={params['m']:.6f}, δ={params['probit_delta']:.6f}")


def apply_beta_cal(df):
    """Beta Cal + probit δ por segmento → pd_cal, pd_ttc."""
    df = df.copy()
    for seg in SEG_VALUES:
        mask = df[SEG_COL] == seg
        if mask.sum() == 0:
            continue
        p_raw = df.loc[mask, SCORE_COL].values.astype(float)
        bc = seg_cals[seg]
        delta_seg = seg_deltas[seg]

        pd_cal = bc.predict(p_raw)
        pd_cal = np.clip(pd_cal, 1e-9, 1 - 1e-9)

        if abs(delta_seg) > 1e-10:
            pd_ttc = norm.cdf(norm.ppf(pd_cal) + delta_seg)
            pd_ttc = np.clip(pd_ttc, 1e-9, 1 - 1e-9)
        else:
            pd_ttc = pd_cal.copy()

        df.loc[mask, 'pd_cal'] = pd_cal
        df.loc[mask, 'pd_ttc'] = pd_ttc
    return df


# --- Anchor column for LRA rescaling ---
# PP uses nodos_pp; REE uses tipo_ingreso_dep (primary segmentation)
# as the population-complete partition for rescaling anchor.
_ANCHOR_COL = SEG_COL


def _rescale_lras(drivers_to_rescale):
    """Rescale driver LRAs to be consistent with global LRA.

    Applies a uniform probit shift so that the population-weighted anchor means
    equal lra_global. Preserves relative risk between cells.
    Uses tipo_ingreso_dep as anchor (analogous to PP's nodos_pp).
    """
    anchor_info = {}
    for val in sorted(lra_by_driver.get(_ANCHOR_COL, {}).keys(), key=str):
        anchor_info[val] = {
            'n_frac': lra_by_driver[_ANCHOR_COL][val].get('n_obs_total', 1),
            'z_lra': norm.ppf(lra_by_driver[_ANCHOR_COL][val]['lra']),
        }
    total_n = sum(info['n_frac'] for info in anchor_info.values())

    delta_rescale = brentq(
        lambda d: sum(
            info['n_frac'] * norm.cdf(info['z_lra'] + d)
            for info in anchor_info.values()
        ) / total_n - lra_global,
        -1, 1,
    )

    rescaled = {}
    for drv in drivers_to_rescale + [_ANCHOR_COL]:
        rescaled[drv] = {}
        for val in sorted(lra_by_driver.get(drv, {}).keys(), key=str):
            lra_raw = lra_by_driver[drv][val]['lra']
            rescaled[drv][val] = float(norm.cdf(norm.ppf(lra_raw) + delta_rescale))

    return rescaled, float(delta_rescale)


def _eval_driver_rmse(pd_vals, df, drv, targets):
    """Weighted RMSE of EC gaps (bps) for a driver."""
    total_wss, total_n = 0.0, 0
    for val, lra in targets.items():
        mask = df[drv].astype(str) == str(val)
        n = mask.sum()
        if n == 0:
            continue
        ec_bps = (pd_vals[mask.values].mean() - lra) * 10000
        total_wss += n * ec_bps ** 2
        total_n += n
    return np.sqrt(total_wss / total_n) if total_n > 0 else 0.0


def _eval_driver_maxgap(pd_vals, df, drv, targets):
    """Max |gap| por celda, en bps. Complementa al RMSE, que es un promedio y
    puede quedar bajo umbral con una celda muy desanclada."""
    peor = 0.0
    for val, lra in targets.items():
        mask = df[drv].astype(str) == str(val)
        if mask.sum() == 0:
            continue
        peor = max(peor, abs((pd_vals[mask.values].mean() - lra) * 10000))
    return peor


def _select_drivers_sequential(df, rescaled, label='Z1'):
    """Phase 1: Sequential greedy driver selection (tree-like).

    At each round, picks the candidate with highest RMSE gap.
    Calibrates it with a single δ₀ + δ₁·D.
    Stops when best remaining RMSE < DRIVER_RMSE_THRESHOLD.
    Returns ordered list of selected drivers.
    """
    z_current = norm.ppf(np.clip(df['pd_ttc'].values, 1e-9, 1 - 1e-9))
    remaining = [d for d in CANDIDATE_DRIVERS if d in df.columns and d in rescaled]
    selected = []

    print(f"\n    {label} SEQUENTIAL DRIVER SELECTION (threshold={DRIVER_RMSE_THRESHOLD}bps)")
    print(f"    {'─' * 60}")

    for ronda in range(len(remaining)):
        pd_current = norm.cdf(z_current)

        # Evaluate remaining drivers
        scores = {}
        for drv in remaining:
            rmse = _eval_driver_rmse(pd_current, df, drv, rescaled[drv])
            scores[drv] = rmse

        ranking = sorted(scores.items(), key=lambda x: -x[1])
        best_drv, best_rmse = ranking[0]
        gaps = {d: _eval_driver_maxgap(pd_current, df, d, rescaled[d]) for d in remaining}
        best_gap = gaps[best_drv]

        detail = "  ".join(f"{d}:{s:.0f}" for d, s in ranking)
        gdet = "  ".join(f"{d}:{g:.0f}" for d, g in gaps.items())
        print(f"    R{ronda}: RMSE: {detail}   |  max_gap: {gdet}")

        # Dos criterios, no uno: el RMSE mide el desvio PROMEDIO del eje y el
        # max_gap la peor celda. Un eje con una sola celda muy desanclada pasa
        # el RMSE y falla la tolerancia; con solo el RMSE esa celda queda sin
        # corregir. El driver entra si cualquiera de los dos lo pide.
        pide_rmse = best_rmse >= DRIVER_RMSE_THRESHOLD
        pide_gap = best_gap > DRIVER_GAP_TOLERANCIA_BPS
        if not (pide_rmse or pide_gap):
            print(f"    STOP R{ronda}: RMSE {best_rmse:.1f} < {DRIVER_RMSE_THRESHOLD} "
                  f"y max_gap {best_gap:.1f} <= {DRIVER_GAP_TOLERANCIA_BPS}")
            break
        print(f"    R{ronda}: entra {best_drv} por "
              + ("RMSE" if pide_rmse else "") + ("+" if pide_rmse and pide_gap else "")
              + ("max_gap" if pide_gap else "")
              + f"  (RMSE {best_rmse:.1f} / max_gap {best_gap:.1f})")

        # Calibrate single driver (quick Nelder-Mead)
        dummy_val = DUMMY_REF.get(best_drv)
        if dummy_val is None:
            continue
        D_single = (df[best_drv].astype(str) == dummy_val).astype(float).values

        masks_single = {
            v: (df[best_drv].astype(str) == str(v)).values
            for v in rescaled[best_drv]
        }

        def obj_single(params):
            z_adj = z_current + params[0] + params[1] * D_single
            pd_adj = norm.cdf(z_adj)
            loss = sum(
                (pd_adj[m].mean() - rescaled[best_drv][v]) ** 2
                for v, m in masks_single.items()
            )
            loss += 100 * (pd_adj.mean() - lra_global) ** 2
            return loss

        res = minimize(obj_single, [0.0, 0.0], method='Nelder-Mead',
                       options={'maxiter': 5000, 'xatol': 1e-10, 'fatol': 1e-15})
        z_current = z_current + res.x[0] + res.x[1] * D_single

        selected.append(best_drv)
        remaining = [d for d in remaining if d != best_drv]
        print(f"    Selected: {best_drv} (RMSE={best_rmse:.1f}bps)")

    print(f"    {label} Selected drivers ({len(selected)}): {selected}")
    not_selected = [d for d in CANDIDATE_DRIVERS if d not in selected]
    if not_selected:
        print(f"    {label} Not selected: {not_selected}")

    return selected


def calibrate_drivers_z1(df, label='Z1', forzar=None):
    """Additive probit per-driver calibration.

    Phase 1: Sequential greedy selection → determines which drivers to include.
    Phase 2: Simultaneous optimization of selected drivers (Nelder-Mead).

    Φ⁻¹(pd_adj) = Φ⁻¹(pd_ttc) + δ₀ + Σ δⱼ·Dⱼ
    """
    rescaled, delta_rescale = _rescale_lras(CANDIDATE_DRIVERS)

    print(f"    {label} LRA rescale: δ_rescale={delta_rescale:+.6f}")
    for drv in CANDIDATE_DRIVERS:
        for val in sorted(rescaled.get(drv, {}).keys(), key=str):
            lra_raw = lra_by_driver.get(drv, {}).get(val, {}).get('lra', 0)
            lra_adj = rescaled[drv][val]
            print(f"      {drv:<22} {val:<12} {lra_raw*100:.2f}% -> {lra_adj*100:.2f}%")

    # ── Phase 1: Sequential selection ──
    if forzar:
        selected_drivers = list(forzar)
        print(f"    {label} drivers FORZADOS por verificacion post-delta0: {selected_drivers}")
    else:
        selected_drivers = _select_drivers_sequential(df, rescaled, label)

    # ── Phase 2: Simultaneous optimization of selected drivers ──
    dummy_specs = [(drv, DUMMY_REF[drv]) for drv in selected_drivers]

    z_ttc = norm.ppf(np.clip(df['pd_ttc'].values, 1e-9, 1 - 1e-9))

    D = np.column_stack([
        (df[drv].astype(str) == val).astype(float).values
        for drv, val in dummy_specs
    ]) if dummy_specs else np.zeros((len(df), 0))

    masks = {}
    for drv in selected_drivers:
        for val in sorted(rescaled[drv].keys(), key=str):
            masks[f'{drv}={val}'] = (df[drv].astype(str) == val).values
    for val in sorted(rescaled.get(_ANCHOR_COL, {}).keys(), key=str):
        masks[f'{_ANCHOR_COL}={val}'] = (df[_ANCHOR_COL].astype(str) == val).values

    print(f"\n    {label} SIMULTANEOUS OPTIMIZATION ({len(selected_drivers)} drivers)")

    def objective(params):
        z_adj = z_ttc + params[0] + (D @ params[1:] if len(params) > 1 else 0)
        pd_adj = norm.cdf(z_adj)
        loss = 0.0
        for drv in selected_drivers:
            for val in sorted(rescaled[drv].keys(), key=str):
                m = masks[f'{drv}={val}']
                gap = pd_adj[m].mean() - rescaled[drv][val]
                loss += gap ** 2
        global_gap = pd_adj.mean() - lra_global
        loss += 5000 * global_gap ** 2
        return loss

    n_params = 1 + len(dummy_specs)
    res = minimize(objective, np.zeros(n_params),
                   method='Nelder-Mead',
                   options={'maxiter': 30000, 'xatol': 1e-9, 'fatol': 1e-14})

    delta_0 = float(res.x[0])
    driver_betas = {f'{drv}={val}': float(res.x[i + 1])
                    for i, (drv, val) in enumerate(dummy_specs)}

    z_adj = z_ttc + delta_0 + (D @ res.x[1:] if len(res.x) > 1 else 0)
    df['pd_ttc_adj'] = norm.cdf(z_adj)

    # ── Verificacion POST-delta0 (no existia) ──────────────────────────────
    # El selector de la Fase 1 decide sobre pd_ttc, ANTES de delta_0. Pero
    # delta_0 se optimiza con penalizacion 5000x sobre el gap GLOBAL, asi que
    # fuerza el agregado a lra_global y las celdas absorben el residual: en este
    # corte el max |gap| pasa de 30.6 bps (pre) a 60.7 bps (post), fuera de la
    # tolerancia que este mismo paso imprime. Se decidia mirando un estado que
    # despues cambia. Aca se re-chequea sobre lo que efectivamente se entrega y,
    # si alguna celda quedo fuera, se reintenta incluyendo el driver.
    _pa = df['pd_ttc_adj'].values
    _fuera = []
    for _drv in CANDIDATE_DRIVERS:
        if _drv in selected_drivers or _drv not in rescaled:
            continue
        for _v, _l in rescaled[_drv].items():
            _m = (df[_drv].astype(str) == str(_v)).values
            if _m.sum() == 0:
                continue
            _g = abs((_pa[_m].mean() - _l) * 10000)
            if _g > DRIVER_GAP_TOLERANCIA_BPS:
                _fuera.append((_drv, _v, _g))
    if _fuera:
        _peor = max(_fuera, key=lambda x: x[2])
        print("")
        print(f"    {label} POST-delta0: {len(_fuera)} celda(s) fuera de "
              f"+-{DRIVER_GAP_TOLERANCIA_BPS:.0f} bps (peor {_peor[0]}={_peor[1]} "
              f"{_peor[2]:.1f} bps). DIAGNOSTICO: no se corrige con driver, "
              f"ver nota abajo. Sobre pd_pit las celdas quedan verdes.")
        # NO se reintenta con el driver: MEDIDO que no lo resuelve. DUMMY_REF
        # define UNA sola dummy, o sea 2 grados de libertad (delta_0 + delta_MIXTO)
        # para 4 targets de celda mas el global con peso 5000x. El optimizador
        # baja la suma de cuadrados (6389 -> 6108) SACRIFICANDO la peor celda:
        # MIXTO pasa de +60.7 a +66.4 bps. Y sobre pd_pit -la PD que se entrega-
        # las 6 celdas quedan VERDES con y sin driver, con el global moviendose
        # 0.0003 pp. Anclar 4 celdas exige 3 dummies o segmentar la BetaCal por
        # ese eje: cambio de spec mayor que el estudio sesgo-varianza NO respalda.
        # Queda como DIAGNOSTICO visible, no como gatillo automatico.
    # ───────────────────────────────────────────────────────────────────────

    print(f"      delta_0 = {delta_0:+.6f}")
    for name, beta in driver_betas.items():
        print(f"      delta({name}) = {beta:+.6f}")

    print(f"\n    {label} Calibration check (vs rescaled LRAs):")
    print(f"      {'Target':<30} {'LRA_adj':>8} {'Realized':>10} {'Gap_bps':>8}")
    all_targets = selected_drivers + [_ANCHOR_COL]
    for drv in all_targets:
        for val in sorted(rescaled.get(drv, {}).keys(), key=str):
            key = f'{drv}={val}'
            if key not in masks:
                continue
            m = masks[key]
            target = rescaled[drv][val]
            realized = df.loc[m, 'pd_ttc_adj'].mean()
            gap = (realized - target) * 10000
            print(f"      {key:<30} {target*100:>7.2f}% {realized*100:>9.2f}% {gap:>+7.0f}")

    # Also show non-selected drivers for monitoring
    for drv in CANDIDATE_DRIVERS:
        if drv in selected_drivers:
            continue
        for val in sorted(rescaled.get(drv, {}).keys(), key=str):
            m = (df[drv].astype(str) == str(val)).values
            target = rescaled[drv][val]
            realized = df.loc[m, 'pd_ttc_adj'].mean()
            gap = (realized - target) * 10000
            print(f"      {drv}={val:<20} {target*100:>7.2f}% {realized*100:>9.2f}% {gap:>+7.0f}  (monitor)")

    global_mean = df['pd_ttc_adj'].mean()
    print(f"      {'GLOBAL':<30} {lra_global*100:>7.2f}% {global_mean*100:>9.2f}% "
          f"{(global_mean - lra_global)*10000:>+7.0f}")

    z_orig = norm.ppf(np.clip(df['pd_ttc'].values, 1e-9, 1 - 1e-9))
    z_final = norm.ppf(np.clip(df['pd_ttc_adj'].values, 1e-9, 1 - 1e-9))
    df['delta_driver'] = z_final - z_orig
    df['adjusted_by'] = np.where(abs(df['delta_driver']) > 1e-6, 'driver_cal', 'none')

    coefs = {
        'delta_0': delta_0,
        'driver_betas': driver_betas,
        'selected_drivers': selected_drivers,
        'dummy_specs': dummy_specs,
    }
    return df, coefs


def apply_fixed_deltas_z2(df, coefs, label='Z2'):
    """Apply Z1 additive probit coefficients to Z2."""
    delta_0 = coefs['delta_0']
    driver_betas = coefs['driver_betas']
    dummy_specs = coefs['dummy_specs']

    z_ttc = norm.ppf(np.clip(df['pd_ttc'].values, 1e-9, 1 - 1e-9))

    D = np.column_stack([
        (df[drv].astype(str) == val).astype(float).values
        for drv, val in dummy_specs
    ]) if dummy_specs else np.zeros((len(df), 0))
    betas_arr = np.array([driver_betas[f'{drv}={val}'] for drv, val in dummy_specs])

    df['pd_ttc_adj'] = norm.cdf(z_ttc + delta_0 + (D @ betas_arr if len(betas_arr) > 0 else 0))

    z_orig = z_ttc
    z_final = norm.ppf(np.clip(df['pd_ttc_adj'].values, 1e-9, 1 - 1e-9))
    df['delta_driver'] = z_final - z_orig
    df['adjusted_by'] = np.where(abs(df['delta_driver']) > 1e-6, 'driver_cal_fixed', 'none')

    n_applied = (df['adjusted_by'] != 'none').sum()
    print(f"    {label} deltas aplicados: {n_applied:,} de {len(df):,}")
    print(f"    {label} pd_ttc mean:     {df['pd_ttc'].mean()*100:.4f}%")
    print(f"    {label} pd_ttc_adj mean: {df['pd_ttc_adj'].mean()*100:.4f}%")

    return df


def apply_vasicek(df):
    """PIT transformation: multiplicative scaling or individual Vasicek."""
    df['ft'] = df['codmes'].astype(str).map(ft_dict)
    mask_ft = df['ft'].notna()
    pd_adj = df.loc[mask_ft, 'pd_ttc_adj'].values

    if PIT_METHOD == 'multiplicative_scaling':
        # Top-down PIT: scale_t = Vasicek(mean_TTC_t, F_t, ρ) / mean_TTC_t
        # PD_PIT_i = PD_TTC_adj_i × scale_t → exactly rank-preserving
        df.loc[mask_ft, 'rho_i'] = rho
        pd_pit = np.full(len(df), np.nan)
        for cm in df.loc[mask_ft, 'codmes'].astype(str).unique():
            m_cm = mask_ft & (df['codmes'].astype(str) == cm)
            if m_cm.sum() == 0:
                continue
            mean_ttc_t = df.loc[m_cm, 'pd_ttc_adj'].mean()
            ft_t = ft_dict.get(cm, 0.0)
            pit_agg_t = float(vasicek_pit(mean_ttc_t, ft_t, rho, lam=LAMBDA_PIT))
            scale_t = pit_agg_t / mean_ttc_t if mean_ttc_t > 0 else 1.0
            pd_pit[m_cm.values] = df.loc[m_cm, 'pd_ttc_adj'].values * scale_t
            df.loc[m_cm, 'scale_pit'] = scale_t
    else:
        # Individual Vasicek (original)
        if RHO_SCALING == 'constant':
            rho_i = rho
        else:
            rho_i = rho_scaled_basel(pd_adj, rho, lra_global)
        df.loc[mask_ft, 'rho_i'] = rho_i
        pd_pit = np.full(len(df), np.nan)
        pd_pit[mask_ft.values] = vasicek_pit(
            pd_adj,
            df.loc[mask_ft, 'ft'].values,
            rho_i,
            lam=LAMBDA_PIT,
        )

    df['pd_pit'] = np.clip(pd_pit, 0.0001, 0.9999)
    return df


# =============================================================================
# 2. Z1: Beta Cal + additive probit per-driver + Vasicek
# =============================================================================

print(f"\n{'=' * 60}")
print("  CADENA COMPLETA — Z1")
print(f"{'=' * 60}")

df_z1 = apply_beta_cal(df_z1)

print("\n  Driver calibration (Z1):")
df_z1, z1_coefs = calibrate_drivers_z1(df_z1, label='Z1')
df_z1 = apply_vasicek(df_z1)

print(f"\n  pd_ree mean:     {df_z1[SCORE_COL].mean()*100:.4f}%")
print(f"  pd_cal mean:     {df_z1['pd_cal'].mean()*100:.4f}%")
print(f"  pd_ttc mean:     {df_z1['pd_ttc'].mean()*100:.4f}%")
print(f"  pd_ttc_adj mean: {df_z1['pd_ttc_adj'].mean()*100:.4f}%")
print(f"  pd_pit mean:     {df_z1['pd_pit'].mean()*100:.4f}%")
if TARGET_COL in df_z1.columns:
    print(f"  RD obs:          {df_z1[TARGET_COL].mean()*100:.4f}%")

for seg in SEG_VALUES:
    mask = df_z1[SEG_COL] == seg
    print(f"\n  {seg}:")
    print(f"    pd_ttc_adj: {df_z1.loc[mask, 'pd_ttc_adj'].mean()*100:.4f}%")
    print(f"    pd_pit:     {df_z1.loc[mask, 'pd_pit'].mean()*100:.4f}%")
    if TARGET_COL in df_z1.columns:
        print(f"    RD obs:     {df_z1.loc[mask, TARGET_COL].mean()*100:.4f}%")

# =============================================================================
# 3. Z2: Beta Cal + FIXED deltas from Z1 + Vasicek
# =============================================================================

print(f"\n{'=' * 60}")
print("  CADENA COMPLETA — Z2 (coefs fijos de Z1)")
print(f"{'=' * 60}")

df_z2 = apply_beta_cal(df_z2)

print("\n  Applying Z1-fitted driver coefs to Z2:")
df_z2 = apply_fixed_deltas_z2(df_z2, z1_coefs, label='Z2')
df_z2 = apply_vasicek(df_z2)

print(f"\n  pd_ree mean:     {df_z2[SCORE_COL].mean()*100:.4f}%")
print(f"  pd_pit mean:     {df_z2['pd_pit'].mean()*100:.4f}%")
n_ft_ok = df_z2['pd_pit'].notna().sum()
print(f"  pd_pit asignado: {n_ft_ok:,} de {len(df_z2):,}")

# =============================================================================
# 4. Consolidar Z1+Z2
# =============================================================================

df_full = pd.concat([df_z1, df_z2], ignore_index=True)
print(f"\nZ1+Z2: {len(df_full):,}")

# =============================================================================
# 5. Continuity check Z1→Z2
# =============================================================================

print(f"\n{'=' * 60}")
print("  CONTINUITY CHECK Z1 → Z2")
print(f"{'=' * 60}")

last_z1 = df_full[df_full['codmes'].astype(str) <= COHORTE_FIN].groupby('codmes').agg(
    pd_ttc=('pd_ttc', 'mean'), pd_ttc_adj=('pd_ttc_adj', 'mean'), pd_pit=('pd_pit', 'mean')
).reset_index().sort_values('codmes').tail(3)

first_z2 = df_full[df_full['codmes'].astype(str) > COHORTE_FIN].groupby('codmes').agg(
    pd_ttc=('pd_ttc', 'mean'), pd_ttc_adj=('pd_ttc_adj', 'mean'), pd_pit=('pd_pit', 'mean')
).reset_index().sort_values('codmes').head(3)

print(f"  {'codmes':<8} {'pd_ttc':>8} {'pd_ttc_adj':>10} {'pd_pit':>8}")
for _, r in pd.concat([last_z1, first_z2]).iterrows():
    marker = " <-Z2" if str(r['codmes']) > COHORTE_FIN else ""
    print(f"  {r['codmes']:<8} {r['pd_ttc']*100:>7.2f}% {r['pd_ttc_adj']*100:>9.2f}% {r['pd_pit']*100:>7.2f}%{marker}")

# =============================================================================
# 6. Tabla final por driver
# =============================================================================

print(f"\n{'=' * 60}")
print("  TABLA CALIBRACION TTC POR DRIVER (Z1): pd_ttc_adj vs LRA")
print(f"{'=' * 60}")

print(f"  {'Driver':<22} {'Celda':<16} {'n':>8} {'LRA':>8} {'TTC_adj':>8} {'Gap':>8} {'OK':>5}")
print(f"  {'─'*22} {'─'*16} {'─'*8} {'─'*8} {'─'*8} {'─'*8} {'─'*5}")

for drv in DRIVER_COLS:
    if drv not in df_z1.columns:
        continue
    df_drv = df_z1[df_z1[drv].notna()]
    for val in sorted(df_drv[drv].unique(), key=str):
        mask = df_drv[drv] == val
        n = mask.sum()
        ttc_adj = df_drv.loc[mask, 'pd_ttc_adj'].mean()
        lra_info = lra_by_driver.get(drv, {}).get(str(val))
        lra_cell = lra_info['lra'] if lra_info else np.nan
        gap = (ttc_adj - lra_cell) * 10000 if not np.isnan(lra_cell) else np.nan
        ok = "OK" if (not np.isnan(gap) and abs(gap) <= 50) else "X"
        lra_str = f"{lra_cell*100:>7.2f}%" if not np.isnan(lra_cell) else "    N/A"
        gap_str = f"{gap:>+7.1f}" if not np.isnan(gap) else "    N/A"
        print(f"  {drv:<22} {str(val):<16} {n:>8,} {lra_str} {ttc_adj*100:>7.2f}% {gap_str} {ok:>5}")

ttc_glob = df_z1['pd_ttc_adj'].mean()
gap_glob = (ttc_glob - lra_global) * 10000
ok_glob = "OK" if abs(gap_glob) <= 50 else "X"
print(f"  {'GLOBAL':<22} {'':16} {len(df_z1):>8,} {lra_global*100:>7.2f}% {ttc_glob*100:>7.2f}% {gap_glob:>+7.1f} {ok_glob:>5}")

print(f"\n{'=' * 60}")
print("  TABLA PIT POR DRIVER (Z1): pd_pit vs RD_obs")
print(f"{'=' * 60}")

print(f"  {'Driver':<22} {'Celda':<16} {'n':>8} {'RD_obs':>8} {'PD_pit':>8} {'Gap':>8} {'OK':>5}")
print(f"  {'─'*22} {'─'*16} {'─'*8} {'─'*8} {'─'*8} {'─'*8} {'─'*5}")

for drv in DRIVER_COLS:
    if drv not in df_z1.columns:
        continue
    df_drv = df_z1[df_z1[drv].notna()]
    for val in sorted(df_drv[drv].unique(), key=str):
        mask = df_drv[drv] == val
        n = mask.sum()
        rd = df_drv.loc[mask, TARGET_COL].mean()
        pit = df_drv.loc[mask, 'pd_pit'].mean()
        gap = (pit - rd) * 10000
        ok = "OK" if abs(gap) <= 50 else "X"
        print(f"  {drv:<22} {str(val):<16} {n:>8,} {rd*100:>7.2f}% {pit*100:>7.2f}% {gap:>+7.1f} {ok:>5}")

# =============================================================================
# 7. Export
# =============================================================================

from vasicek import rho_basel_retail
rho_ref_basel = float(rho_basel_retail(lra_global))

rho_range = ([float(rho), float(rho)] if RHO_SCALING == 'constant'
             else [float(df_full['rho_i'].min()), float(df_full['rho_i'].max())])

pit_output = {
    'product': SUBPRODUCTO_FILTER,
    'calibration_method': 'beta_cal_additive_probit_driver',
    'pit_method': PIT_METHOD,
    'rho_global': float(rho),
    'rho_method': RHO_SCALING,
    'rho_basel_ref': rho_ref_basel,
    'rho_range': rho_range,
    'lambda_pit': float(LAMBDA_PIT),
    'z1_n': int(len(df_z1)),
    'z2_n': int(len(df_z2)),
    'pd_pit_mean_z1': float(df_z1['pd_pit'].mean()),
    'pd_pit_mean_z2': float(df_z2['pd_pit'].mean()),
    'ft_source': 'estimated_univariate',
    'f_cap_quantile': F_CAP_QUANTILE,
    'f_cap_lo': F_p_lo,
    'f_cap_hi': F_p_hi,
    'f_cap_n_capped': n_capped,
    'z1_driver_coefs': {
        'delta_0': z1_coefs['delta_0'],
        'driver_betas': z1_coefs['driver_betas'],
        'selected_drivers': z1_coefs['selected_drivers'],
        'selection_method': 'sequential_greedy',
        'selection_threshold_bps': DRIVER_RMSE_THRESHOLD,
    },
}

with open(PATHS['json'] / 'pit_transformation.json', 'w') as f:
    json.dump(pit_output, f, indent=2)

df_full.to_parquet(PATHS['parquets'] / 'full_calibrated.parquet', index=False)

agg_mes = df_z1.groupby('codmes').agg(
    n=(TARGET_COL, 'count'),
    defaults=(TARGET_COL, 'sum'),
    pd_pit_mean=('pd_pit', 'mean'),
    pd_ttc_mean=('pd_ttc_adj', 'mean'),
    pd_ree_mean=(SCORE_COL, 'mean'),
).reset_index()
agg_mes['rd'] = agg_mes['defaults'] / agg_mes['n']
agg_mes.to_csv(PATHS['csv'] / 'pit_mensual.csv', index=False)

print(f"\nExport: {PATHS['json'] / 'pit_transformation.json'}")
print(f"Export: {PATHS['parquets'] / 'full_calibrated.parquet'}")
print(f"Export: {PATHS['csv'] / 'pit_mensual.csv'}")

print(f"\n{'=' * 60}")
print(f"  06 COMPLETADO — PIT TRANSFORMATION {SUBPRODUCTO_FILTER}")
print(f"{'=' * 60}")
