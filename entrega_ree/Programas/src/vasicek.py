"""Transformacion Vasicek single-factor PD_TTC -> PD_PIT y helpers de bandas.

Convencion:
    f_t = (Phi^-1(LRA) - sqrt(1-rho) * Phi^-1(RD_t)) / sqrt(rho)
    PD_PIT = Phi((Phi^-1(PD_TTC) - sqrt(rho) * f_t) / sqrt(1-rho))

f_t > 0 cuando RD < LRA (ciclo mejor que promedio).
"""
from typing import Union

import numpy as np
from scipy.stats import norm
from sklearn.base import BaseEstimator, TransformerMixin


def _validate_rho(rho) -> None:
    r = np.asarray(rho, dtype=float)
    if np.any(r <= 0) or np.any(r >= 1):
        raise ValueError(f'rho fuera de (0,1): min={r.min()}, max={r.max()}')


def rho_basel_retail(pd_ttc: Union[np.ndarray, float]) -> np.ndarray:
    """Basel IRB retail-other correlation function: ρ = f(PD).

    ρ decreases with PD: low-PD obligors have higher systematic correlation.
    Source: Basel II/III IRB framework, BIS (2006).
    """
    pd = np.clip(np.asarray(pd_ttc, dtype=float), 1e-9, 1 - 1e-9)
    e = np.exp(-35.0 * pd)
    d = 1.0 - np.exp(-35.0)
    return 0.03 * (1.0 - e) / d + 0.16 * (1.0 - (1.0 - e) / d)


def rho_scaled_basel(pd_ttc: Union[np.ndarray, float],
                     rho_global: float,
                     pd_global: float) -> np.ndarray:
    """Per-client ρ using Basel retail shape scaled to estimated ρ_global.

    ρ_i = ρ_global × ρ_Basel(PD_i) / ρ_Basel(PD_global)

    Preserves product-level calibration while differentiating by PD level.
    """
    rho_ref = rho_basel_retail(pd_global)
    rho_i = rho_global * rho_basel_retail(pd_ttc) / rho_ref
    return np.clip(rho_i, 0.001, 0.999)


def ft_implicit(rd: float, lra: float, rho: float) -> float:
    """Despeja f_t desde RD observada bajo Vasicek single-factor."""
    if rd is None or rd <= 0 or rd >= 1 or lra <= 0 or lra >= 1 or rho <= 0 or rho >= 1:
        return np.nan
    return (norm.ppf(lra) - np.sqrt(1 - rho) * norm.ppf(rd)) / np.sqrt(rho)


def vasicek_pit(pd_ttc: Union[np.ndarray, float],
                f_t: Union[np.ndarray, float],
                rho: Union[np.ndarray, float],
                lam: float = 1.0) -> np.ndarray:
    """PD_PIT = Φ((Φ⁻¹(PD_TTC) - √ρ·λ·ft) / √(1-ρ)).

    rho can be scalar (global) or array (per-client, Basel-scaled).
    Ref: Doemoetoer & Illes (2025), ECB Guide v4 par.213.
    """
    _validate_rho(rho)
    if not (0 < lam <= 1):
        raise ValueError(f'lambda fuera de (0,1]: {lam}')
    p = np.clip(np.asarray(pd_ttc, dtype=float), 1e-9, 1 - 1e-9)
    r = np.asarray(rho, dtype=float)
    return norm.cdf((norm.ppf(p) - np.sqrt(r) * lam * np.asarray(f_t, dtype=float)) / np.sqrt(1 - r))


def vasicek_banda(pd_pit: Union[np.ndarray, float], rho: float, q: float) -> np.ndarray:
    """Banda Vasicek alrededor de PD_PIT al percentil q."""
    _validate_rho(rho)
    p = np.clip(np.asarray(pd_pit, dtype=float), 1e-9, 1 - 1e-9)
    return norm.cdf((norm.ppf(p) + np.sqrt(rho) * norm.ppf(q)) / np.sqrt(1 - rho))


class VasicekTransformer(BaseEstimator, TransformerMixin):
    """Aplica Vasicek single-factor a un DataFrame con columnas pd_ttc y f_t.

    Genera nueva columna `out_col` (no muta el DataFrame de entrada).
    """

    def __init__(self, rho: float, lra: float = None, lam: float = 1.0,
                 ttc_col: str = 'pd_ttc', ft_col: str = 'f_t', out_col: str = 'pd_pit'):
        _validate_rho(rho)
        self.rho = rho
        self.lam = lam
        self.lra = lra
        self.ttc_col = ttc_col
        self.ft_col = ft_col
        self.out_col = out_col

    def fit(self, X, y=None):
        return self

    def transform(self, X):
        for c in (self.ttc_col, self.ft_col):
            if c not in X.columns:
                raise KeyError(f'columna requerida ausente: {c}')
        out = X.copy()
        out[self.out_col] = vasicek_pit(out[self.ttc_col].values,
                                         out[self.ft_col].values, self.rho,
                                         lam=self.lam)
        return out
