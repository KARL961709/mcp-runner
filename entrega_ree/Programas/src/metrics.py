"""Metricas de calibracion y validacion: Brier, ECE, Wilson, Jeffreys, Gini, PSI, bootstrap."""
from typing import Callable, Tuple

import numpy as np
import pandas as pd
from scipy import stats as sp_stats
from sklearn.metrics import roc_auc_score


def brier(y: np.ndarray, p: np.ndarray) -> float:
    """Brier score: mean((y - p)^2). Mejor cuando bajo."""
    return float(np.mean((np.asarray(y) - np.asarray(p)) ** 2))


def log_loss(y: np.ndarray, p: np.ndarray, eps: float = 1e-12) -> float:
    p = np.clip(np.asarray(p, dtype=float), eps, 1 - eps)
    y = np.asarray(y, dtype=float)
    return float(-np.mean(y * np.log(p) + (1 - y) * np.log(1 - p)))


def ece(y: np.ndarray, p: np.ndarray, n_bins: int = 10) -> float:
    """Expected Calibration Error con bins de igual ancho en [0, 1]."""
    p = np.asarray(p)
    y = np.asarray(y)
    bins = np.linspace(0, 1, n_bins + 1)
    out = 0.0
    for i in range(n_bins):
        if i == n_bins - 1:
            mask = (p >= bins[i]) & (p <= bins[i + 1])
        else:
            mask = (p >= bins[i]) & (p < bins[i + 1])
        if mask.sum() == 0:
            continue
        out += mask.sum() / len(p) * abs(p[mask].mean() - y[mask].mean())
    return float(out)


def wilson_ic(k: int, n: int, z: float = 1.96, mult: float = 1.0) -> Tuple[float, float]:
    """Intervalo Wilson para una proporcion binomial.

    Para portafolios low-default (hipotecario) se aplica un multiplicador sobre
    el z-score base: z_eff = z * sqrt(mult).  Con mult=3 y z=1.96 se obtiene
    z_eff ≈ 3.394, produciendo un IC de cobertura ≈99.9% que absorbe la alta
    varianza muestral de k/N cuando k < 20 (BCBS WP-14).
    """
    if n <= 0:
        return (np.nan, np.nan)
    z_eff = z * np.sqrt(mult)
    p = k / n
    den = 1 + z_eff ** 2 / n
    centro = (p + z_eff ** 2 / (2 * n)) / den
    spread = z_eff * np.sqrt(p * (1 - p) / n + z_eff ** 2 / (4 * n ** 2)) / den
    return (max(0.0, centro - spread), min(1.0, centro + spread))


def jeffreys_ic(k: int, n: int, alpha: float = 0.05) -> Tuple[float, float]:
    """Intervalo credible Jeffreys (Bayesiano) para una proporcion binomial.

    Prior no-informativo: Beta(0.5, 0.5) (prior de referencia de Jeffreys).
    Posterior: Beta(k + 0.5, n - k + 0.5).

    Este intervalo es EXACTO (no asume normalidad), captura la asimetria natural
    de la distribucion binomial y mantiene cobertura correcta incluso con pocos
    defaults (k < 20), donde Wilson sobre-cubre al imponer simetria.

    Args:
        k: numero de defaults observados
        n: tamaño de muestra
        alpha: nivel de significancia (0.10 → IC90%, 0.05 → IC95%)

    Returns:
        (lo, hi): limites inferior y superior del intervalo credible
    """
    if n <= 0:
        return (np.nan, np.nan)
    a = k + 0.5
    b = n - k + 0.5
    lo = sp_stats.beta.ppf(alpha / 2, a, b) if k > 0 else 0.0
    hi = sp_stats.beta.ppf(1 - alpha / 2, a, b)
    return (max(0.0, float(lo)), min(1.0, float(hi)))


def coverage_jeffreys(df_trim: pd.DataFrame, score_col: str,
                      target_col: str = 'rd24', n_col: str = 'n_obs',
                      def_col: str = 'def',
                      alpha: float = 0.05) -> Tuple[int, int]:
    """Cuantos trims tienen score (mean PD_PIT) dentro del Jeffreys IC de RD.

    Args:
        alpha: nivel de significancia (0.10 → IC90%, 0.05 → IC95%)
    """
    obs = df_trim[df_trim[target_col].notna()]
    if len(obs) == 0:
        return (0, 0)
    inside = 0
    for _, row in obs.iterrows():
        lo, hi = jeffreys_ic(int(row[def_col]), int(row[n_col]), alpha=alpha)
        if lo <= row[score_col] <= hi:
            inside += 1
    return (inside, len(obs))


def gini(y: np.ndarray, scores: np.ndarray) -> float:
    """Gini = 2 * AUC - 1. nan si no hay variacion en y."""
    y = np.asarray(y)
    if y.sum() == 0 or y.sum() == len(y):
        return np.nan
    return 2 * roc_auc_score(y, scores) - 1


def coverage_wilson(df_trim: pd.DataFrame, score_col: str,
                    target_col: str = 'rd24', n_col: str = 'n_obs',
                    def_col: str = 'def', z: float = 1.96,
                    mult: float = 1.0) -> Tuple[int, int]:
    """Cuantos trims tienen score (mean PD_PIT) dentro del Wilson IC de RD.

    mult: multiplicador low-default (mult=3 para hipotecario).
    z_eff = z * sqrt(mult) se pasa internamente a wilson_ic.
    """
    obs = df_trim[df_trim[target_col].notna()]
    if len(obs) == 0:
        return (0, 0)
    inside = 0
    for _, row in obs.iterrows():
        lo, hi = wilson_ic(int(row[def_col]), int(row[n_col]), z=z, mult=mult)
        if lo <= row[score_col] <= hi:
            inside += 1
    return (inside, len(obs))


def coverage_wilson_dual(df_trim: pd.DataFrame, score_col: str,
                         target_col: str = 'rd24', n_col: str = 'n_obs',
                         def_col: str = 'def', mult: float = 3.0) -> dict:
    """Cobertura Wilson dual: IC95% e IC70% con multiplicador low-default.

    Por defecto mult=3 (hipotecario, BCBS WP-14).  Para portafolios alto-default
    usar mult=1.
      - IC95%: z_base=1.96, z_eff = 1.96 * sqrt(mult) ≈ 3.394 con mult=3.
      - IC70%: z_base=1.04, z_eff = 1.04 * sqrt(mult) ≈ 1.80  con mult=3.
    """
    return {
        'IC95': coverage_wilson(df_trim, score_col, target_col, n_col, def_col,
                                z=1.96, mult=mult),
        'IC70': coverage_wilson(df_trim, score_col, target_col, n_col, def_col,
                                z=1.04, mult=mult),
    }


def psi(reference: np.ndarray, observed: np.ndarray, bins: int = 10,
        edges: np.ndarray = None) -> float:
    """Population Stability Index entre dos distribuciones.

    PSI = sum_i (a_i - b_i) * log(a_i / b_i)
    donde a_i, b_i son frecuencias relativas en bin i.
    Convenciones:
      < 0.10 : sin shift relevante
      < 0.25 : shift moderado
      >=0.25 : shift material
    """
    reference = np.asarray(reference, dtype=float)
    observed = np.asarray(observed, dtype=float)
    if edges is None:
        edges = np.quantile(reference, np.linspace(0, 1, bins + 1))
        edges[0] = -np.inf
        edges[-1] = np.inf
    a, _ = np.histogram(reference, bins=edges)
    b, _ = np.histogram(observed, bins=edges)
    a = a / max(a.sum(), 1)
    b = b / max(b.sum(), 1)
    eps = 1e-6
    a = np.clip(a, eps, None)
    b = np.clip(b, eps, None)
    return float(np.sum((a - b) * np.log(a / b)))


def bootstrap_ic(estimator_fn: Callable[[np.ndarray, np.ndarray], np.ndarray],
                 X: np.ndarray, y: np.ndarray, n_boot: int = 1000,
                 alpha: float = 0.05, cluster: np.ndarray = None,
                 random_state: int = 42) -> dict:
    """IC bootstrap de un estimador.

    Args:
        estimator_fn: funcion (X, y) -> vector de coeficientes
        cluster: si se pasa, hace cluster bootstrap (resamplea grupos completos)

    Returns:
        dict con 'mean', 'lo', 'hi', 'samples' (matriz n_boot x dim)
    """
    rng = np.random.default_rng(random_state)
    base = estimator_fn(X, y)
    dim = len(base)
    samples = np.zeros((n_boot, dim))
    if cluster is not None:
        cluster = np.asarray(cluster)
        unique_clusters = np.unique(cluster)
    for i in range(n_boot):
        if cluster is not None:
            sampled = rng.choice(unique_clusters, size=len(unique_clusters), replace=True)
            mask = np.concatenate([np.where(cluster == c)[0] for c in sampled])
        else:
            mask = rng.integers(0, len(X), size=len(X))
        try:
            samples[i] = estimator_fn(X[mask], y[mask])
        except Exception:
            samples[i] = np.nan
    samples = samples[~np.isnan(samples).any(axis=1)]
    lo = np.quantile(samples, alpha / 2, axis=0)
    hi = np.quantile(samples, 1 - alpha / 2, axis=0)
    mean = samples.mean(axis=0)
    return {'mean': mean, 'lo': lo, 'hi': hi, 'samples': samples, 'point': base}
