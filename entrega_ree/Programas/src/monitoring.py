"""Marco de monitoreo de calibracion PP.

Semaforo canonico del pipeline (ec_status):
  - Banda EC x2 (Low Default): verde [-30%,+20%], amarillo [-60%,+40%], rojo resto.
    EC = (RD - PD) / PD ; EC>0 = subestimacion (lado estricto).
  - Moderacion por test de Jeffreys bilateral (p>5%, PD dentro IC95%): si el
    desvio no es significativo (ruido), baja UN nivel (rojo->amarillo->verde).
  Usado en 07_monitoring, 11_charts_doc y los Excel 09/09b.

Marcos auxiliares (no usados en el pipeline, se conservan para referencia):
  1. Sistema Secuencial EC + Binomial (reporte_calibracion).
  2. Bandas Vasicek (reporte_vasicek_bands).
"""
from typing import Tuple

import numpy as np
from scipy.stats import binom, norm

try:
    from metrics import jeffreys_ic
except ImportError:  # ejecucion como paquete
    from src.metrics import jeffreys_ic


# Bandas EC de referencia (x1). Convencion: EC = (RD - PD) / PD.
#   EC > 0  ->  RD > PD  ->  SUBESTIMACION (peligroso; lado mas estricto).
#   EC < 0  ->  RD < PD  ->  SOBRESTIMACION (conservador; lado mas laxo).
# Referencia x1:  Calibrado EC ∈ [-15%, +10%]  |  Ligeramente EC ∈ [-30%, +20%].
EC_BASE = {
    'calibrado_lo':       -0.15,
    'calibrado_hi':       +0.10,
    'ligeramente_lo':     -0.30,
    'ligeramente_hi':     +0.20,
}

# Low Default Portfolio (PP REE): bandas x2 sobre la referencia.
#   Calibrado (verde)    EC ∈ [-30%, +20%]
#   Ligeramente (amar.)  EC ∈ [-60%, +40%]
#   Descalibrado (rojo)  resto
# NOTA (PROVISIONAL): el multiplicador x2 es provisional. La definicion formal del
# multiplicador (x1 vs x2) y su validacion (Monte Carlo de falsos positivos) quedan
# pendientes en los Lineamientos de Desarrollo y Monitoreo de Calibracion (deadline Jun-2026).
EC_MULT_DEFAULT = 2.0


def ec_bands(mult: float = EC_MULT_DEFAULT) -> dict:
    return {k: v * mult for k, v in EC_BASE.items()}


def ec_relativo(rd: float, pd: float) -> float:
    if pd is None or pd <= 0:
        return float('nan')
    return float((rd - pd) / pd)


def _ec_band(ec: float, mult: float = EC_MULT_DEFAULT) -> str:
    if np.isnan(ec):
        return 'nan'
    b = ec_bands(mult)
    if b['calibrado_lo'] <= ec <= b['calibrado_hi']:
        return 'calibrado'
    if b['ligeramente_lo'] <= ec < b['calibrado_lo'] or b['calibrado_hi'] < ec <= b['ligeramente_hi']:
        return 'ligeramente'
    return 'descalibrado'


# Semaforo: 0 verde, 1 amarillo, 2 rojo.
_SEMAFORO = {0: 'verde', 1: 'amarillo', 2: 'rojo'}


def ec_nivel(ec: float, mult: float = EC_MULT_DEFAULT) -> int:
    """Nivel base por banda EC (0 verde / 1 amarillo / 2 rojo; -1 si nan)."""
    return {'calibrado': 0, 'ligeramente': 1, 'descalibrado': 2}.get(_ec_band(ec, mult=mult), -1)


def jeffreys_pass(k, n, pd_val, alpha: float = 0.05):
    """Test de Jeffreys bilateral: ¿PD dentro del IC credible (1-alpha)?

    PD dentro del IC95% de Beta(k+0.5, n-k+0.5)  <=>  p-value bilateral > 5%
    => el desvio RD-PD no es significativo (ruido). Devuelve None si no evaluable.
    """
    if n is None or n <= 0 or pd_val is None or np.isnan(pd_val) or not (0 < pd_val < 1):
        return None
    lo, hi = jeffreys_ic(int(round(k)), int(round(n)), alpha=alpha)
    return bool(lo <= pd_val <= hi)


def jeffreys_pvalue(k, n, pd_val) -> float:
    """P-value bilateral del test de Jeffreys: 2*min(F, 1-F), F = Beta.cdf(PD; k+.5, n-k+.5)."""
    from scipy.stats import beta as _beta
    if n is None or n <= 0 or pd_val is None or np.isnan(pd_val) or not (0 < pd_val < 1):
        return float('nan')
    F = float(_beta.cdf(pd_val, k + 0.5, n - k + 0.5))
    return float(2.0 * min(F, 1.0 - F))


def ec_status(ec: float, jeffreys_ok: bool, mult: float = EC_MULT_DEFAULT) -> str:
    """Semaforo final = nivel por banda EC x{mult}, bajado UN nivel si pasa Jeffreys (p>5%).

    Solo puede mejorar (rojo -> amarillo -> verde), nunca empeorar.
    """
    if ec is None or np.isnan(ec):
        return 'nan'
    nivel = ec_nivel(ec, mult=mult)
    if nivel < 0:
        return 'nan'
    if jeffreys_ok and nivel > 0:
        nivel -= 1
    return _SEMAFORO[nivel]


def binomial_ic(k: int, n: int, alpha: float = 0.05) -> Tuple[float, float]:
    """Intervalo de confianza Binomial exacto (Clopper-Pearson)."""
    if n <= 0:
        return (np.nan, np.nan)
    from scipy.stats import beta as beta_dist
    if k == 0:
        lo = 0.0
    else:
        lo = float(beta_dist.ppf(alpha / 2, k, n - k + 1))
    if k == n:
        hi = 1.0
    else:
        hi = float(beta_dist.ppf(1 - alpha / 2, k + 1, n - k))
    return (max(0.0, lo), min(1.0, hi))


def binomial_pvalue(k: int, n: int, pd: float) -> float:
    """P-value Binomial one-sided segun signo de EC.

    Si RD > PD (subestimacion): p = P(X >= k | N, PD).
    Si RD < PD (sobreestimacion): p = P(X <= k | N, PD).
    """
    if n <= 0 or pd is None or not (0 < pd < 1):
        return float('nan')
    rd = k / n
    if rd >= pd:
        return float(binom.sf(k - 1, n, pd))
    return float(binom.cdf(k, n, pd))


def traffic_light_binomial(ec: float, p_value: float,
                           mult: float = EC_MULT_DEFAULT) -> str:
    """Semaforo combinando EC y p-value binomial."""
    if np.isnan(ec) or np.isnan(p_value):
        return 'nan'
    band_ec = _ec_band(ec, mult=mult)

    if p_value > 0.05:
        band_p = 'posible_ruido'
    elif p_value > 0.01:
        band_p = 'desvio_moderado'
    else:
        band_p = 'desvio_fuerte'

    matriz = {
        ('calibrado',     'posible_ruido'):    'verde',
        ('calibrado',     'desvio_moderado'):  'verde',
        ('calibrado',     'desvio_fuerte'):    'amarillo',
        ('ligeramente',   'posible_ruido'):    'amarillo',
        ('ligeramente',   'desvio_moderado'):  'amarillo',
        ('ligeramente',   'desvio_fuerte'):    'rojo',
        ('descalibrado',  'posible_ruido'):    'amarillo',
        ('descalibrado',  'desvio_moderado'):  'rojo',
        ('descalibrado',  'desvio_fuerte'):    'rojo',
    }
    return matriz.get((band_ec, band_p), 'nan')


def sistema_secuencial(k: int, n: int, pd_pred: float,
                       mult_ec: float = EC_MULT_DEFAULT,
                       alpha: float = 0.05) -> dict:
    """Evalua una celda mensual con sistema secuencial EC x1 -> Binomial.

    PASO 1: EC relativo -> nivel inicial.
    PASO 2: Binomial IC -> modera (solo puede BAJAR, nunca subir).
    """
    rd = k / n if n > 0 else float('nan')
    ec = ec_relativo(rd, pd_pred)

    # Paso 1: EC -> nivel inicial
    band = _ec_band(ec, mult=mult_ec)
    nivel = {'calibrado': 0, 'ligeramente': 1, 'descalibrado': 2}.get(band, -1)

    # Paso 2: Binomial IC -> moderacion
    lo, hi = binomial_ic(k, n, alpha=alpha)
    dentro = lo <= pd_pred <= hi

    moderado = False
    if dentro and nivel > 0:
        nivel -= 1
        moderado = True

    # P-value adicional para diagnostico
    p_binom = binomial_pvalue(k, n, pd_pred)

    _NOMBRES = {0: 'verde', 1: 'amarillo', 2: 'rojo'}
    _ACCIONES = {0: 'Continuar Uso', 1: 'Plan Contingencia', 2: 'Recalibrar'}

    return {
        'n': n, 'k': k, 'rd': rd, 'pd_pred': pd_pred,
        'ec': ec,
        'band_ec': band,
        'binom_lo': lo, 'binom_hi': hi, 'binom_dentro': dentro,
        'p_binomial': p_binom,
        'moderado': moderado,
        'nivel': nivel,
        'semaforo': _NOMBRES.get(nivel, 'nan'),
        'accion': _ACCIONES.get(nivel, 'N/A'),
        'mult_ec': mult_ec, 'alpha': alpha,
    }


def plan_accion(status: str) -> str:
    return {
        'verde':    'Continuar Uso',
        'amarillo': 'Plan Contingencia',
        'rojo':     'Recalibrar',
    }.get(status, 'N/A')


def reporte_calibracion(df, pd_col: str, target_col: str = 'flg_target_pp_12m',
                        period_col: str = 'codmes', mult_ec: float = EC_MULT_DEFAULT,
                        alpha: float = 0.05, label: str = '') -> dict:
    """Reporte completo de calibracion de 3 capas para PP.

    Capa 1: Metricas propias (Brier, ECE).
    Capa 2: Test formal Pool — Binomial IC95%.
    Capa 3: Diagnostico mensual — sistema secuencial EC x1 -> Binomial.
    """
    try:
        from src.metrics import brier, ece
    except ImportError:
        from metrics import brier, ece

    df_valid = df[df[pd_col].notna() & df[target_col].notna()].copy()

    # Capa 1: Metricas propias
    y = df_valid[target_col].values
    p = df_valid[pd_col].values
    metricas = {
        'brier': brier(y, p),
        'ece': ece(y, p),
        'n_total': len(df_valid),
        'k_total': int(y.sum()),
    }

    # Capa 2: Test Pool Binomial IC95%
    n_pool = metricas['n_total']
    k_pool = metricas['k_total']
    pd_pool = float(p.mean())
    rd_pool = k_pool / n_pool if n_pool > 0 else float('nan')
    pool_lo, pool_hi = binomial_ic(k_pool, n_pool, alpha=alpha)
    pool_dentro = pool_lo <= pd_pool <= pool_hi

    pool = {
        'n': n_pool, 'k': k_pool,
        'rd': rd_pool, 'pd_mean': pd_pool,
        'binom_lo': pool_lo, 'binom_hi': pool_hi,
        'dentro': pool_dentro,
    }

    # Capa 3: Diagnostico mensual
    period_results = []
    for period in sorted(df_valid[period_col].unique()):
        sub = df_valid[df_valid[period_col] == period]
        n_t = len(sub)
        k_t = int(sub[target_col].sum())
        pd_t = float(sub[pd_col].mean())
        res = sistema_secuencial(k_t, n_t, pd_t, mult_ec=mult_ec, alpha=alpha)
        res['period'] = period
        period_results.append(res)

    conteo = {'verde': 0, 'amarillo': 0, 'rojo': 0}
    for r in period_results:
        conteo[r['semaforo']] = conteo.get(r['semaforo'], 0) + 1

    n_rojos = conteo.get('rojo', 0)
    dictamen = 'CALIBRADO' if (pool_dentro and n_rojos < 2) else 'REQUIERE REVISION'

    return {
        'label': label,
        'metricas': metricas,
        'pool': pool,
        'mensual': period_results,
        'conteo': conteo,
        'n_periodos': len(period_results),
        'dictamen': dictamen,
    }


# =========================================================================
# Metodo 2: Bandas Vasicek
# =========================================================================

# Parámetros bandas Vasicek para backtesting (Método 2).
# rho_band=0.005: ρ conservador para ancho de banda de confianza
#   (refleja incertidumbre muestral del aggregate PD).
# Q10/Q90: intervalo 80% bajo distribución Vasicek.
# Cobertura 80% = estándar backtesting calibración (ECB par. 246).
VASICEK_RHO_BAND = 0.005
VASICEK_Q_LO = 0.10
VASICEK_Q_HI = 0.90


def vasicek_quantile(pd_val: float, rho: float, q: float) -> float:
    """Quantile q de la distribucion Vasicek del default rate."""
    return float(norm.cdf(
        (norm.ppf(pd_val) + np.sqrt(rho) * norm.ppf(q)) / np.sqrt(1 - rho)
    ))


def vasicek_quantile_array(pd_arr, rho: float, q: float):
    """Vectorizado."""
    pd_arr = np.asarray(pd_arr, dtype=float)
    return norm.cdf(
        (norm.ppf(pd_arr) + np.sqrt(rho) * norm.ppf(q)) / np.sqrt(1 - rho)
    )


def reporte_vasicek_bands(df, pd_col: str, target_col: str = 'flg_target_pp_12m',
                          period_col: str = 'codmes',
                          rho: float = VASICEK_RHO_BAND,
                          q_lo: float = VASICEK_Q_LO,
                          q_hi: float = VASICEK_Q_HI,
                          max_fuera: int = 2,
                          label: str = '') -> dict:
    """Backtesting PIT con bandas Vasicek.

    Para cada periodo, verifica si RD observada cae dentro de
    [Vasicek_q_lo(PD_PIT), Vasicek_q_hi(PD_PIT)] con rho dado.
    Criterio binario: dentro / fuera.
    """
    df_valid = df[df[pd_col].notna() & df[target_col].notna()].copy()

    period_results = []
    for period in sorted(df_valid[period_col].unique()):
        sub = df_valid[df_valid[period_col] == period]
        n_t = len(sub)
        k_t = int(sub[target_col].sum())
        rd_t = k_t / n_t if n_t > 0 else float('nan')
        pd_t = float(sub[pd_col].mean())

        band_lo = vasicek_quantile(pd_t, rho, q_lo)
        band_hi = vasicek_quantile(pd_t, rho, q_hi)
        dentro = band_lo <= rd_t <= band_hi
        ec = ec_relativo(rd_t, pd_t)

        period_results.append({
            'period': period,
            'n': n_t, 'k': k_t,
            'rd': rd_t, 'pd_pred': pd_t,
            'ec': ec,
            'band_lo': band_lo, 'band_hi': band_hi,
            'dentro': dentro,
        })

    n_dentro = sum(1 for r in period_results if r['dentro'])
    n_fuera = sum(1 for r in period_results if not r['dentro'])
    n_total = len(period_results)
    pct_dentro = n_dentro / n_total * 100 if n_total > 0 else float('nan')

    dictamen = 'CALIBRADO' if n_fuera <= max_fuera else 'REQUIERE REVISION'

    return {
        'label': label,
        'rho': rho,
        'q_lo': q_lo,
        'q_hi': q_hi,
        'max_fuera': max_fuera,
        'mensual': period_results,
        'n_dentro': n_dentro,
        'n_fuera': n_fuera,
        'n_periodos': n_total,
        'pct_dentro': pct_dentro,
        'dictamen': dictamen,
    }
