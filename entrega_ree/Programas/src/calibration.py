"""Calibradores TTC: Platt POOLED y Beta Calibration (Kull 2017).

Ambos exponen interfaz sklearn: `fit(X, y)` y `transform(X)` donde X es PD_raw.

Solver
------
Ambos calibradores ajustan via **MLE puro con statsmodels.Logit** (no penalizado).

Esta es una decision deliberada de alineamiento con PIPELINE_FINAL (legacy
deployed) y de defensa regulatoria: la version anterior usaba
`sklearn.linear_model.LogisticRegression(C=1e10)`, que pese al `C` muy alto
incluye una regularizacion L2 implicita que comprime ligeramente el alpha
hacia cero. Sobre Z1 IBK (n=15861, def=224) la diferencia era:

    sm.Logit       : alpha=-2.1504693721308437, beta=+0.9371046081733128
    sklearn C=1e10 : alpha=-2.1492357489543665, beta=+0.9370132429670835
    diff           : ~0.0012 en alpha, ~0.0001 en beta

Aunque el sesgo es <0.001 en magnitud absoluta, statsmodels MLE puro es
regulatoriamente mas defendible (estimador no penalizado, errores estandar
e IC95 basados en la matriz de informacion de Fisher consistentes con la
literatura de credit scoring) y reproduce exactamente los coeficientes
deployed en `PIPELINE_FINAL/outputs/calibracion_ibk_FINAL.json`.

Los argumentos legacy `C` y `max_iter` del `__init__` se mantienen por
compatibilidad de API, pero ya no afectan el ajuste (statsmodels no los
necesita). Si en el futuro se requiere regularizacion explicita, usar
`statsmodels.Logit.fit_regularized` antes que volver a sklearn.
"""
from typing import Union

import numpy as np
import statsmodels.api as sm
from scipy.special import expit
from sklearn.base import BaseEstimator, TransformerMixin


def _validate_pd_input(X: Union[np.ndarray, list]) -> np.ndarray:
    p = np.asarray(X, dtype=float).ravel()
    if (p <= 0).any() or (p >= 1).any():
        raise ValueError(f'PD_raw fuera de (0,1): min={p.min()}, max={p.max()}')
    return p


def _validate_target(y: Union[np.ndarray, list], n: int) -> np.ndarray:
    y = np.asarray(y, dtype=float).ravel()
    if len(y) != n:
        raise ValueError(f'len(y)={len(y)} != len(X)={n}')
    if not set(np.unique(y)).issubset({0.0, 1.0}):
        raise ValueError('y debe ser binario {0, 1}')
    return y


def _mle_restringido_monotono(F: np.ndarray, y: np.ndarray,
                              x0: np.ndarray) -> tuple:
    """MLE de Beta Calibration sujeto a a >= 0, b >= 0.

    Condicion de monotonicidad (Kull et al. 2017)
    ---------------------------------------------
    eta(p) = c + a*log(p) - b*log(1-p)  =>  d(eta)/dp = a/p + b/(1-p).
    Multiplicando por p(1-p) > 0, el signo de la derivada es el de
    g(p) = a*(1-p) + b*p, que es LINEAL en p con extremos g(0+)=a y g(1-)=b.
    Una funcion lineal es >= 0 en todo (0,1) sii sus dos extremos lo son, y
    sigmoid es estrictamente creciente. Luego el mapa es no-decreciente en
    (0,1) **sii a >= 0 y b >= 0**.

    Por que L-BFGS-B con cotas y no un clip
    ---------------------------------------
    Aplastar el coeficiente negativo a cero (`max(coef, 0)`) NO es el optimo
    restringido: deja el intercepto estimado bajo el modelo libre, con lo que
    el punto viola estacionariedad. Medido sobre casos sinteticos con la
    restriccion activa, el clip discrepa del KKT en 172 de 306 (error mediano
    31% en la PD media). Con cotas, KKT se resuelve exacto: el optimo puede
    caer en el interior de una cara y ahi el intercepto SE REAJUSTA.

    La funcion solo se invoca cuando el MLE libre es infactible; si es
    factible, el llamador devuelve el MLE sin tocarlo (bit a bit).
    """
    from scipy.optimize import minimize

    def _nll_y_grad(theta):
        eta = np.clip(F @ theta, -35.0, 35.0)
        mu = expit(eta)
        nll = -np.sum(y * np.log(np.maximum(mu, 1e-12)) +
                      (1 - y) * np.log(np.maximum(1 - mu, 1e-12)))
        return nll, F.T @ (mu - y)

    res = minimize(_nll_y_grad, x0, jac=True, method='L-BFGS-B',
                   bounds=[(None, None), (0.0, None), (0.0, None)],
                   options={'maxiter': 5000, 'ftol': 1e-14, 'gtol': 1e-10})
    if not np.all(np.isfinite(res.x)):
        # Degenerado: caer a la cara a=b=0, cuyo optimo cerrado es logit(ybar).
        yb = float(np.clip(y.mean(), 1e-9, 1 - 1e-9))
        return float(np.log(yb / (1 - yb))), 0.0, 0.0
    c, a, b = (float(v) for v in res.x)
    # Las cotas pueden dejar -0.0 o un epsilon negativo por redondeo.
    return c, max(a, 0.0), max(b, 0.0)


class PlattCalibrator(BaseEstimator, TransformerMixin):
    """Calibracion logistica de Platt sobre logit(PD_raw).

    Modelo:
        PD_TTC = sigmoid(alpha + beta * logit(PD_raw))

    Atributos post-fit:
        alpha_ : intercepto
        beta_  : pendiente

    References
    ----------
    Platt, J. (1999). Probabilistic outputs for support vector machines.
    """

    def __init__(self, C: float = 1e10, max_iter: int = 2000):
        # C y max_iter se conservan por compatibilidad de API, pero el
        # solver actual es statsmodels.Logit (MLE puro) y no los usa.
        self.C = C
        self.max_iter = max_iter

    def fit(self, X: np.ndarray, y: np.ndarray) -> 'PlattCalibrator':
        p = _validate_pd_input(X)
        y = _validate_target(y, len(p))
        feat = np.log(p / (1 - p))
        X_design = sm.add_constant(feat.reshape(-1, 1))
        self._fit = sm.Logit(y, X_design).fit(disp=0)
        self.alpha_ = float(self._fit.params[0])
        self.beta_ = float(self._fit.params[1])
        return self

    def transform(self, X: np.ndarray) -> np.ndarray:
        p = _validate_pd_input(X)
        return expit(self.alpha_ + self.beta_ * np.log(p / (1 - p)))

    def predict(self, X: np.ndarray) -> np.ndarray:
        return self.transform(X)

    @property
    def alpha(self):
        return self.alpha_

    @property
    def beta(self):
        return self.beta_


class BetaCalibrator(BaseEstimator, TransformerMixin):
    """Beta Calibration de Kull et al. (2017).

    Modelo con 3 parametros:
        PD_TTC = sigmoid(c + a * log(p) - b * log(1 - p))

    Permite asimetria entre cola baja (peso `a`) y cola alta (peso `b`).

    Atributos post-fit:
        c_, a_, b_

    References
    ----------
    Kull, M., et al. (2017). Beta calibration: a well-founded and
    easily implemented improvement on logistic calibration for binary
    classifiers. AISTATS.
    """

    def __init__(self, C: float = 1e10, max_iter: int = 2000,
                 monotone: bool = False):
        # C y max_iter se conservan por compatibilidad de API; el solver
        # actual es statsmodels.Logit (MLE puro) y no los utiliza.
        self.C = C
        self.max_iter = max_iter
        # monotone=True impone a>=0, b>=0. Ver nota de monotonicidad abajo.
        self.monotone = monotone

    def _features(self, X: np.ndarray) -> np.ndarray:
        p = _validate_pd_input(X)
        return np.column_stack([np.ones(len(p)), np.log(p), -np.log(1 - p)])

    def fit(self, X: np.ndarray, y: np.ndarray) -> 'BetaCalibrator':
        F = self._features(X)
        y = _validate_target(y, len(F))
        # F ya incluye la columna de unos: ajustamos sin intercepto adicional.
        self._fit = sm.Logit(y, F).fit(disp=0)
        self.c_, self.a_, self.b_ = (float(v) for v in self._fit.params)
        self.restriccion_activa_ = False
        if self.monotone and (self.a_ < 0 or self.b_ < 0):
            self.c_, self.a_, self.b_ = _mle_restringido_monotono(
                F, y, x0=np.array([self.c_, max(self.a_, 0.0), max(self.b_, 0.0)]))
            self.restriccion_activa_ = True
        return self

    def transform(self, X: np.ndarray) -> np.ndarray:
        F = self._features(X)
        eta = F @ np.array([self.c_, self.a_, self.b_])
        return expit(eta)

    def predict(self, X: np.ndarray) -> np.ndarray:
        return self.transform(X)

    @property
    def c(self):
        return self.c_

    @property
    def a(self):
        return self.a_

    @property
    def b(self):
        return self.b_
