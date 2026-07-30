# -*- coding: utf-8 -*-
# =============================================================================
# BENCHMARK DE CALIBRADORES — Comportamental PP Reenganche
#   Compara las cinco familias sobre la MISMA poblacion Z1 y con las mismas
#   piezas que usa el pipeline (src/calibration.py, src/metrics.py), en cuatro
#   ejes: ajuste, calibracion en nivel (EC), calibracion por quintil y
#   estabilidad temporal (LOO mes a mes, fuera de muestra).
#   Salida: outputs_v5/json/benchmark_calibradores.json
# =============================================================================
import json
import sys
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.optimize import minimize
from scipy.special import expit
from scipy.stats import norm

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ / 'src'))
warnings.filterwarnings('ignore')

from calibration import BetaCalibrator, PlattCalibrator          # noqa: E402
from metrics import brier, ece, gini, log_loss                   # noqa: E402
from monitoring import ec_relativo                               # noqa: E402

EPS = 1e-12


def _clip(p):
    return np.clip(np.asarray(p, float), EPS, 1 - EPS)


# ---------------------------------------------------------------- calibradores
class ShiftCalibrator:
    """Un parametro: desplaza en escala probit. PD = Phi(Phi^-1(p) + d)."""
    nombre, n_par = 'Shift (probit, 1 par.)', 1

    def fit(self, X, y):
        z = norm.ppf(_clip(X))
        f = lambda d: -np.sum(y * np.log(_clip(norm.cdf(z + d)))
                              + (1 - y) * np.log(_clip(1 - norm.cdf(z + d))))
        self.d_ = float(minimize(f, [0.0], method='Nelder-Mead').x[0])
        return self

    def predict(self, X):
        return norm.cdf(norm.ppf(_clip(X)) + self.d_)


class _Platt:
    nombre, n_par = 'Platt (2 par.)', 2

    def fit(self, X, y):
        self.m_ = PlattCalibrator().fit(_clip(X), y)
        return self

    def predict(self, X):
        return self.m_.predict(_clip(X))


class _Beta:
    def __init__(self, mono):
        self.mono = mono
        self.nombre = 'Beta monotona (3 par.)' if mono else 'Beta libre (3 par.)'
        self.n_par = 3

    def fit(self, X, y):
        self.m_ = BetaCalibrator(monotone=self.mono).fit(_clip(X), y)
        return self

    def predict(self, X):
        return self.m_.predict(_clip(X))


class IsotonicCal:
    nombre, n_par = 'Isotonica (no param.)', np.nan

    def fit(self, X, y):
        from sklearn.isotonic import IsotonicRegression
        self.m_ = IsotonicRegression(out_of_bounds='clip').fit(np.asarray(X, float), y)
        return self

    def predict(self, X):
        return _clip(self.m_.predict(np.asarray(X, float)))


class IsotonicSmooth:
    """Isotonica SUAVIZADA (tipo CIR, Oron & Flournoy 2017): se ajusta la
    isotonica, se colapsan sus bloques planos al centroide y se interpola con
    PCHIP, que preserva la monotonia. El resultado es monotono Y C1 ---es decir
    pasa los DOS criterios estructurales que descartan a la isotonica cruda---,
    de modo que su desempeno es la prueba honesta de si esos criterios cuestan algo."""
    nombre, n_par = 'Isotonica suavizada (CIR)', np.nan

    def fit(self, X, y):
        from sklearn.isotonic import IsotonicRegression
        from scipy.interpolate import PchipInterpolator
        x = np.asarray(X, float)
        yi = IsotonicRegression(out_of_bounds='clip').fit(x, y).predict(x)
        o = np.argsort(x)
        xs, ys = x[o], yi[o]
        # centroide de cada bloque plano de la isotonica
        kx, ky = [], []
        i = 0
        while i < len(ys):
            j = i
            while j + 1 < len(ys) and ys[j + 1] == ys[i]:
                j += 1
            kx.append(xs[i:j + 1].mean())
            ky.append(ys[i])
            i = j + 1
        kx, ky = np.asarray(kx), np.asarray(ky)
        u, idx = np.unique(kx, return_index=True)
        kx, ky = u, ky[idx]
        if len(kx) < 2:                       # degenerado: constante
            self.f_ = lambda z: np.full_like(np.asarray(z, float), ky[0] if len(ky) else 0.0)
        else:
            self.f_ = PchipInterpolator(kx, ky, extrapolate=True)
        self.lo_, self.hi_ = float(ky.min()), float(ky.max())
        return self

    def predict(self, X):
        return _clip(np.clip(self.f_(np.asarray(X, float)), self.lo_, self.hi_))


def familias():
    return [ShiftCalibrator(), _Platt(), _Beta(True), _Beta(False),
            IsotonicCal(), IsotonicSmooth()]


# ------------------------------------------------------------------- metricas
def por_quintil(y, p, raw, k=5):
    """Calibracion por quintil de PD CRUDA (el corte no depende del calibrador,
    de modo que las cinco familias se comparan sobre exactamente los mismos grupos)."""
    q = pd.qcut(pd.Series(raw).rank(method='first'), k, labels=False)
    out = []
    for i in range(k):
        m = q == i
        n, obs, pred = int(m.sum()), float(y[m].mean()), float(p[m].mean())
        out.append({'quintil': i + 1, 'n': n, 'rd_obs': obs, 'pd_pred': pred,
                    'ec': ec_relativo(obs, pred) if pred > 0 else np.nan})
    ecs = [abs(o['ec']) for o in out if np.isfinite(o['ec'])]
    return out, (float(np.max(ecs)) if ecs else np.nan), (float(np.mean(ecs)) if ecs else np.nan)


def evaluar(cal, Xtr, ytr, Xte, yte, raw_te):
    cal.fit(Xtr, ytr)
    p = cal.predict(Xte)
    det, ec_max, ec_med = por_quintil(yte, p, raw_te)
    return {'brier': brier(yte, p), 'logloss': log_loss(yte, p), 'ece': ece(yte, p),
            'gini': gini(yte, p), 'ec_global': ec_relativo(float(yte.mean()), float(p.mean())),
            'ec_quintil_max': ec_max, 'ec_quintil_medio': ec_med, 'quintiles': det}


# ----------------------------------------------------------------------- datos
d = pd.read_parquet(RAIZ / 'outputs_v5/parquets/full_calibrated.parquet')
d['codmes'] = d['codmes'].astype(str)
z1 = d[(d['codmes'] >= '202312') & (d['codmes'] <= '202506') & d['target_12m'].notna()].copy()
SEG = 'tipo_ingreso_dep'
meses = sorted(z1['codmes'].unique())


def _nuevo(cal):
    return type(cal)(cal.mono) if isinstance(cal, _Beta) else type(cal)()


def corrida(sub, etiqueta):
    """Ajusta y evalua las seis familias sobre UNA poblacion (un segmento o el pooled)."""
    X, y = sub['pd'].values, sub['target_12m'].values.astype(float)
    cm = sub['codmes'].values
    out = {'_gini_pd_cruda': gini(y, X)}
    for cal in familias():
        ins = evaluar(cal, X, y, X, y, X)
        filas = []
        oof = np.full(len(y), np.nan)          # prediccion fuera de fold, para el Gini OOF
        for m in meses:
            te = cm == m
            if te.sum() < 5 or len(np.unique(y[~te])) < 2:
                continue
            c = _nuevo(cal).fit(X[~te], y[~te])
            p = c.predict(X[te])
            oof[te] = p
            filas.append({'codmes': m, 'n': int(te.sum()), 'rd': float(y[te].mean()),
                          'pd': float(p.mean()),
                          'ec': ec_relativo(float(y[te].mean()), float(p.mean()))})
        loo = pd.DataFrame(filas)
        ecs = loo['ec'].replace([np.inf, -np.inf], np.nan).dropna()
        rd_w = float((loo['rd'] * loo['n']).sum() / loo['n'].sum())
        pd_w = float((loo['pd'] * loo['n']).sum() / loo['n'].sum())
        v = ~np.isnan(oof)
        out[cal.nombre] = {
            'n_par': cal.n_par, 'in_sample': ins,
            'loo': {'ec_agregado': ec_relativo(rd_w, pd_w),
                    'ec_medio_abs': float(ecs.abs().mean()), 'ec_sd': float(ecs.std(ddof=1)),
                    'ec_max_abs': float(ecs.abs().max()), 'n_folds': len(loo),
                    # Gini sobre la prediccion FUERA de fold: la prueba de si la
                    # ganancia de ordenamiento en muestra transfiere o es sobreajuste.
                    'gini_oof': gini(y[v], oof[v])}}
    return out


def imprimir(res, etiqueta, n, rd):
    print('\n' + '=' * 92)
    print('  %s   n=%s   RD=%.4f%%' % (etiqueta, '{:,}'.format(n), 100 * rd))
    print('=' * 92)
    print('  %-27s %8s %9s %7s %7s %9s %10s %9s'
          % ('CALIBRADOR', 'EC', 'Brier', 'ECE', 'Gini in', 'Gini OOF', 'LOO EC agr', 'LOO|EC|md'))
    for nom, r in [(k,v) for k,v in res.items() if not k.startswith('_')]:
        i, l = r['in_sample'], r['loo']
        print('  %-27s %+8.4f %9.6f %7.4f %7.4f %9.4f %+10.4f %9.4f'
              % (nom, i['ec_global'], i['brier'], i['ece'], i['gini'],
                 l['gini_oof'], l['ec_agregado'], l['ec_medio_abs']))
    print('  (Gini de la PD cruda: %.4f)'%res['_gini_pd_cruda'])
    print('  --- EC por quintil de PD cruda (en muestra) ---')
    print('  %-27s %s' % ('', ''.join('     Q%d' % i for i in range(1, 6))))
    for nom, r in [(k,v) for k,v in res.items() if not k.startswith('_')]:
        print('  %-27s %s' % (nom, ''.join('%+7.3f' % q['ec'] for q in r['in_sample']['quintiles'])))
    q0 = [v for k,v in res.items() if not k.startswith('_')][0]['in_sample']['quintiles']
    print('  %-27s %s' % ('(n)', ''.join('%7d' % q['n'] for q in q0)))
    print('  %-27s %s' % ('(RD obs)', ''.join('%6.2f%%' % (100 * q['rd_obs']) for q in q0)))


todo = {}
POBS = [('POOLED (referencia, no es lo que corre)', z1)]
POBS += [('SEGMENTO %s (calibracion de produccion)' % v, g)
         for v, g in z1.groupby(SEG)]

for etq, sub in POBS:
    r = corrida(sub, etq)
    todo[etq] = {'n': len(sub), 'rd': float(sub['target_12m'].mean()), 'familias': r}
    imprimir(r, etq, len(sub), float(sub['target_12m'].mean()))

out = RAIZ / 'outputs_v5/json/benchmark_calibradores.json'
json.dump({'segmentacion': SEG, 'meses': meses, 'poblaciones': todo},
          open(out, 'w', encoding='utf-8'), indent=1, ensure_ascii=False, default=float)
print('\n  escrito %s' % out.name)
