"""Config — Calibración PD Reenganche (COMP PP REE).

Producto: Reenganche IBK.
Score: pd_ree (arranca 202312).

FUENTE 2026-07-27: maestro reconstruido `disc_model_owner.ds_stk_ree_pp_cal`
(88 meses 201901-202604, sin huecos de calendario). Reemplaza el extract previo.
  - Equivalencia medida contra el maestro anterior: 0 filas del viejo sin
    correspondencia, target_1m 100% idéntico, target_12m con 2 discrepancias
    sobre 116,507, drivers 100% idénticos (ACUERDOS H103-H105).
  - La pd CAMBIÓ de scorecard: v2 (`..._stockpp_itc_reprocesov2`) -> v4
    (`..._stockpp_itc_reen_reprocesov4`). corr = 0.9096, max|dif| = 0.473.
    NO es desalineación de ancla: son modelos distintos (H106). Por eso todo
    coeficiente aguas abajo (BetaCal, δ probit, ρ, λ) se RE-ESTIMA; los valores
    citados abajo son la referencia vigente sobre v2, no el resultado nuevo (A48).
Macro champion: IPC_Lima_var_12m_lag5_ma6 (tasa YoY inflacion, probit univariado).
  Reemplaza IPC_Lima_indice_lag1_ma6 (indice/nivel): el indice solo trackeaba el
  buildup inflacionario (recent R2=0.003); la tasa YoY captura subida Y bajada
  (full R2=0.60, decline 0.75, recent 0.57). Economicamente correcta: la TASA de
  inflacion erosiona ingreso real, no el nivel del indice. R2=0.597, DW=0.94,
  ADF_resid p=0.0004, t_HAC=7.58. IPC Lima = referencia BCRP para todo Peru.
lambda PIT = 1.0 (full PIT); MLE binomial = 1.256 (rechaza lambda=1, p<1e-7).
  Con la tasa el ciclo esta bien temporizado (corr PD-RD recent 0.69) -> respuesta
  plena mejora EC (-18.5%->-4.0%) y Gini (0.5378->0.5433) a la vez.
Betas estimados sobre REE IBK, ventana rd_hist 201901–202504 excl COVID
(64 meses).
"""
import os
from pathlib import Path

import numpy as np

RANDOM_SEED = 202605
np.random.seed(RANDOM_SEED)

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = PROJECT_ROOT / 'src'

# Carpeta de datos RELOCALIZABLE. Default = PROJECT_ROOT/'data' (comportamiento
# historico); REE_DATA_DIR permite montar el flujo en otro arbol (p.ej. una
# entrega con Datos/ y Programas/ separados) sin tocar codigo.
DATA_DIR = Path(os.environ['REE_DATA_DIR']).resolve() if os.environ.get('REE_DATA_DIR') \
    else PROJECT_ROOT / 'data'
# El maestro puede vivir en DATA_DIR o en DATA_DIR/new_data: se resuelve por
# existencia, para que el mismo codigo sirva en los dos layouts.
NEW_DATA_DIR = DATA_DIR / 'new_data'
_MASTER_NAME = os.environ.get('REE_MASTER', 'master_ree_v2.parquet')
MASTER_PARQUET = (NEW_DATA_DIR / _MASTER_NAME) if (NEW_DATA_DIR / _MASTER_NAME).exists() \
    else (DATA_DIR / _MASTER_NAME)
MACRO_PARQUET = DATA_DIR / 'macro_feature_engineering_expanded.parquet'

# Carpeta de salida parametrizable. Acepta ruta RELATIVA (a PROJECT_ROOT, como
# siempre) o ABSOLUTA, necesaria cuando los resultados van fuera del arbol del
# codigo.
_OUTDIR = os.environ.get('REE_OUTDIR', 'outputs')
_OUT_BASE = Path(_OUTDIR).resolve() if Path(_OUTDIR).is_absolute() else PROJECT_ROOT / _OUTDIR
PATHS = {
    'parquets': _OUT_BASE / 'parquets',
    'json': _OUT_BASE / 'json',
    'csv': _OUT_BASE / 'csv',
    'charts': _OUT_BASE / 'charts',
}

# --- Columnas clave ---
TARGET_COL = 'target_12m'
SCORE_COL = 'pd'
TARGET_HORIZON = 12
SUBPRODUCTO_FILTER = 'Reenganche'

# --- Población calibrable (UNA definición, consumida por 00 y 10) ---
# flg_clean, tres buckets del maestro (el 98 no existe):
#   99  OTRA POBLACIÓN — garantía hipotecaria, colaborador IBK, monto pendiente.
#       No es "sucio", es scope: nunca entra, ni al fit ni a la RD histórica.
#   1   pasa todas las honestas                      -> clean
#   0   dirty — malo en el SF o malo en el origen
# Default 'clean' (=1): MEDIDO, reproduce el maestro vigente con 1 registro de
# diferencia sobre 116,507 en 88 meses (H103-H104). 'con_dirty' (<>99) suma 58
# registros; existe para medir sensibilidad sin rehacer el parquet.
CLEAN_MODE = os.environ.get('REE_CLEAN_MODE', 'clean')


def filtro_poblacion(df):
    """Máscara de la población calibrable. Levanta si el maestro no trae
    flg_clean: sin esto un maestro viejo pasaría entero y en silencio."""
    if 'flg_clean' not in df.columns:
        raise KeyError(
            "El maestro no trae 'flg_clean'. Apunta MASTER_PARQUET al maestro "
            "reconstruido (master_ree_v2.parquet) o define REE_MASTER."
        )
    if CLEAN_MODE == 'clean':
        return df['flg_clean'] == 1
    if CLEAN_MODE == 'con_dirty':
        return df['flg_clean'] != 99
    raise ValueError(f"REE_CLEAN_MODE invalido: {CLEAN_MODE!r} (clean|con_dirty)")


# --- Ventanas temporales ---
# Nota: ECB par. 236(d)(ii) recomienda 20 años de indicador económico
# para proporción de años malos. Datos internos desde 2019 (6 años).
# Per ECB par. 237(b): cuando datos internos insuficientes para periodo
# completo, usar series externas o extrapolación. Limitación documentada.
#
# DOS FRONTERAS DISTINTAS — no confundirlas:
#   COHORTE_FIN  = frontera de MADUREZ. Última cohorte con target_12m cerrado.
#                  Acota el fit, la LRA, ρ y el modelo macro.
#   RD_HIST_FIN  = frontera de DATO. Último mes con filas.
#                  Acota el centrado de F (05, 06), el chain-ladder (10, que
#                  NECESITA las cohortes inmaduras) y el rango de reportes (09).
# Medidas sobre el maestro 2026-07-27 (ver bloque FUENTE arriba):
#   pd disponible     202312..202604 (29 meses)   -> SCORE_INI / COHORTE_INI / Z2_FIN
#   target_12m maduro 201901..202506 (78 meses)   -> COHORTE_FIN
#   fit clean&calib   202312..202506 (19m, n=26,348)
SCORE_INI = '202312'
COHORTE_INI = '202312'
# COHORTE_FIN / Z2_INI parametrizables para holdout temporal (default = producción).
# Holdout "3 meses antes": REE_COHORTE_FIN=202503 REE_Z2_INI=202504 → test 202504-202506.
COHORTE_FIN = os.environ.get('REE_COHORTE_FIN', '202506')
Z2_INI = os.environ.get('REE_Z2_INI', '202507')
Z2_FIN = '202604'
RD_HIST_INI = '201901'
RD_HIST_FIN = '202604'

# --- COVID exclusion (todo 2020) ---
COVID_EXCL_MONTHS = [f'2020{m:02d}' for m in range(1, 13)]
EXCL_COVID_FOR_RHO = True

# --- Exclusión spike inflacionario (2022H2-2023H1) — solo para LRA ---
# Criterio: IPC Lima anual > 6% (2× techo meta BCRP 3%).
# IPC > 6%: 202112–202306 (18 meses, pico 8.81% en 202206).
# Impacto en RD rezagado ~12m del shock IPC → spike RD: 202207–202306.
# Excluido de LRA per ECB par. 236(d)(iv): periodo no representativo.
# Se excluye SOLO de LRA, NO de ρ ni macro (esos necesitan el spike).
INFLATION_EXCL_MONTHS = [f'2022{m:02d}' for m in range(7, 13)] + \
                        [f'2023{m:02d}' for m in range(1, 7)]
LRA_EXCL_MONTHS = COVID_EXCL_MONTHS + INFLATION_EXCL_MONTHS

# --- Segmentación ---
SEG_COL = 'tipo_ingreso_dep'
SEG_VALUES = ['DEP', 'NO DEP']

# --- Drivers adicionales ---
CANDIDATE_DRIVERS = ['tipo_ingreso_cs']
DUMMY_REF = {'tipo_ingreso_cs': 'MIXTO'}
DRIVER_COLS = [SEG_COL, 'tipo_ingreso_cs']

# --- Macro univariado ---
# CAMBIO 2026-05: champion = IPC_Lima_var_12m_lag5_ma6 (tasa YoY inflacion).
# Reemplaza IPC_Lima_indice_lag1_ma6 (indice/nivel): el indice solo trackeaba
# el buildup inflacionario (recent R2=0.003); la tasa YoY captura subida Y
# bajada (full R2=0.60, decline 0.75, recent 0.57). Economicamente correcta:
# la TASA de inflacion erosiona ingreso real, no el nivel del indice.
MACRO_CHAMPION_VARS = ['IPC_Lima_var_12m_lag5_ma6']
MACRO_SPEC = 'PROBIT'
# Betas a estimar por el pipeline (step 03).
# Se inicializan como None; step 03 los calcula y guarda en JSON.
MACRO_BETAS = None

# --- Filtro de regimen macro (F9) ---
# R2 minimo del modelo macro en CADA ventana de regimen. Evita variables
# ciegas a algun regimen: el indice de nivel (champion previo) tenia
# R2_reciente=0.003 (solo veia el buildup inflacionario, no el enfriamiento)
# pese a pasar todos los filtros formales (R2/DW/ADF/Shapiro/sign/OOT).
# La tasa YoY pasa con holgura en las 4 ventanas. Umbral uniforme 0.45.
# Step 03 lo evalua y aborta si la variable no pasa (gate duro).
REGIME_R2_MIN = float(os.environ.get('REE_REGIME_R2_MIN', '0.45'))
# Los cierres derivan de COHORTE_FIN, NO son literales: con literal fijo un
# holdout (REE_COHORTE_FIN=202503) evaluaría el gate de régimen sobre meses que
# el holdout no debe ver — fuga silenciosa que dejaría el gate en verde.
# Los ARRANQUES sí son fijos: marcan regímenes económicos, no disponibilidad.
REGIME_WINDOWS = {
    'full':     ('201901', COHORTE_FIN),   # ventana completa (excl COVID)
    'subida':   ('202101', '202305'),      # buildup inflacionario (RD creciente)
    'bajada':   ('202306', COHORTE_FIN),   # enfriamiento (RD decreciente)
    'reciente': ('202401', COHORTE_FIN),   # regimen actual benigno
}

# --- Partial adjustment factor PIT ---
# Lambda a estimar/calibrar. Inicio con 1.0 (full PIT) y luego
# se puede ajustar basado en MLE binomial individual-level.
LAMBDA_PIT = 1.0

# --- Ventana de centrado del factor sistémico F (Dömötör & Illés 2025, eq 9) ---
# CAMBIO 2026-07-27. Antes el centrado se colgaba de RD_HIST_FIN y quedaban
# CUATRO ventanas distintas en juego, con el comentario del paso 06 declarando
# una que no era la implementada:
#     lra.json n_meses        = 54   (LRA: excl COVID + spike)
#     vasicek_rho.json        = 66   (rho y macro: excl COVID)
#     comentario del codigo   = "consistent with LRA and rho"
#     IMPLEMENTADO            = 76   (201901-202604, con 10 meses SIN RD observada)
# eq(9) pide Sigma f_t = 0 sobre la ventana en que se calculo la LRA, para que
# la PD PIT sea neutral exactamente ahi. Se fija esa: la de la LRA.
# Medido sobre este corte (PD_pit Z1 / Z2 / EC global):
#     76m implementada  3.3598% / 2.6996% / -0.0138   <- centraba sobre pronostico macro
#     66m rho observado 3.2521% / 2.6261% / +0.0188   <- el EC cambia de SIGNO
#     54m LRA (eq 9)    3.5775% / 2.9009% / -0.0738   <- la elegida, y la conservadora
# La ventana ya no se deriva de RD_HIST_FIN: es explicita y overrideable.
F_CENTER_INI = os.environ.get('REE_F_CENTER_INI', RD_HIST_INI)
F_CENTER_FIN = os.environ.get('REE_F_CENTER_FIN', COHORTE_FIN)
# 'lra' = excl COVID + spike (54m, eq 9) | 'covid' = solo COVID (66m) | 'none'
F_CENTER_EXCL = os.environ.get('REE_F_CENTER_EXCL', 'lra')


def f_center_meses(codmeses):
    """Meses que entran al centrado de F. Un solo lugar, consumido por 05 y 06."""
    ex = {'lra': set(LRA_EXCL_MONTHS),
          'covid': set(COVID_EXCL_MONTHS),
          'none': set()}[F_CENTER_EXCL]
    return [cm for cm in codmeses
            if F_CENTER_INI <= str(cm) <= F_CENTER_FIN and str(cm) not in ex]

# --- Cap anti-extrapolación F_centered ---
# P5/P95 de distribución F_centered sobre ventana LRA.
# Previene estados macro extremos produciendo ajustes PIT irrazonables.
# Rostampour (2025): errores forecast macro se componen sin capping.
# Práctica estándar: P5/P95 (conservador) o P1/P99 (relajado).
F_CAP_QUANTILE = 0.95

# --- LRA method ---
# 'median' por robustez a outliers residuales post-exclusión.
# Nota: ECB par. 235 refiere "average" (mean). Median es desviación
# conservadora justificada por ventana corta con eventos extremos.
# Documentado per ECB par. 236(d)(iv).
LRA_METHOD = 'median'

# --- Basel IRB retail ρ floor ---
RHO_FLOOR = 0.0332

# --- ρ scaling in Vasicek PIT ---
# 'constant': ρ_global for all individuals (rank-preserving within period)
# 'basel_retail': ρ_i = ρ_global × ρ_Basel(PD_i) / ρ_Basel(PD_global)
RHO_SCALING = 'constant'

# --- PIT method ---
# 'vasicek_individual': standard per-individual Vasicek (may distort rankings)
# 'multiplicative_scaling': PD_PIT_i = PD_TTC_i × scale_t (rank-preserving)
PIT_METHOD = 'vasicek_individual'

# --- Umbral level check BetaCal (probit δ shift) ---
# CAMBIO 2026-07-27: 0.005 (50 bps) -> 0.0 (anclar SIEMPRE).
# El valor 50 bps quedaba DOMINADO en los dos criterios a la vez y era el
# único de {0,25,50,100,200} que dispara en un segmento y no en el otro
# (gaps medidos: DEP -39.15 bps, NO DEP -78.79 bps):
#   - RMSE del gap TTC vs LRA reescalada: 27.97 bps contra 18.41 en todos los demás
#   - EC de pd_pit en DEP: +14.31% con 3 meses ROJOS, contra +4.52% con 1
# Y su derivación original ("~2× SE, SE≈18bps") omitía el SE de la LRA, que es
# el otro término de la resta y es 3× mayor (49.81/59.98 bps, moving-block L=6):
# SE(gap) = 52.67/61.67 -> el umbral implicado por esa misma regla es 105/123
# bps, no 50. P(la decisión de shiftear DEP se voltea al remuestrear la LRA)
# = 0.356: era una moneda al aire.
# Con 0.0 no hay parámetro libre, no hay decisión que pueda voltearse, y los dos
# segmentos reciben el mismo trato. Costo OOT medido: +0.000115 de logloss
# (+0.088%), p_boot = 0.803.
# NOTA: el anclaje TTC VINCULANTE lo entrega el paso 06 (penalización 5000x
# sobre el gap global), no este switch. Ver ACUERDOS H127, A57.
LEVEL_CHECK_THRESHOLD = float(os.environ.get('REE_LEVEL_CHECK', '0.0'))

# --- Restricción de monotonicidad en BetaCal (Kull a>=0, b>=0) ---
# El mapa de Kull es no-decreciente en (0,1) sii a>=0 y b>=0. El MLE libre la
# viola en el segmento DEP en 8 de 10 ventanas de reajuste, porque ahí b NO
# ESTÁ IDENTIFICADO: z=-0.34, |z|>1.96 en 0/10 folds, LR(H0:b=0)=0.21 (p~0.65),
# por colinealidad de log(p) con -log(1-p) (corr(a,b)=-0.816).
# Medido: nunca empeora el logloss (8/8 celdas embargo x ancla), baja la
# varianza del estimador 17.4% y lleva las no-monotonías de 8/10 a 0/10.
# Sobre el corte vigente la restricción está INACTIVA (b=+0.1167 en DEP), o sea
# no altera la PD de hoy: el beneficio es preventivo sobre la próxima
# recalibración. Ver ACUERDOS H123-H125, A56.
BETACAL_MONOTONE = os.environ.get('REE_BETACAL_MONOTONE', '1') == '1'

# --- Umbral materialidad selección de driver (bps) ---
# Derivado: 1.5 × SE_mediana de celdas de driver en Z1.
# SE_mediana = 20.1 bps (binomial, N típico ~5,500-14,000, RD ~3-4%).
# 1.5 × 20.1 ≈ 30 bps → gap inferior al noise floor estadístico
# no justifica driver adicional (riesgo de sobreajuste).
# Consistente con ECB par. 234: "diferencias materiales".
DRIVER_RMSE_THRESHOLD = 30.0

# --- Tolerancia de anclaje por celda (bps) ---
# El paso 06 ya imprimia 'X' cuando |gap| > 50 bps por celda, pero ese numero
# estaba HARDCODEADO en dos sitios y no gobernaba ninguna decision: el selector
# de drivers decide por RMSE PONDERADO, que es un promedio y esconde la peor
# celda. Medido en este corte: RMSE 25.1 bps -> el selector descarta el driver,
# mientras MIXTO (55.7% de Z1) queda a +68.2 bps y DEP_NO_CS a +57.2, ambas
# fuera de la tolerancia que el mismo paso imprime. Dos criterios que se
# contradicen sobre el mismo dato.
# Se unifica: el driver entra si el RMSE supera su umbral O si ALGUNA celda
# excede esta tolerancia. No se inventa un numero nuevo — se usa el que el
# pipeline ya declaraba.
DRIVER_GAP_TOLERANCIA_BPS = float(os.environ.get('REE_DRIVER_GAP_TOL', '50'))

# --- Método de proyección de RD (port del método PP_VC vía Comportamental BN) ---
# Fuente: 'Comportamental BN - Validación/pipeline/32_resumen_proyeccion.py',
# que a su vez es port tal cual de PP_VC (compute_projections_v123).
#   mediana : RD_mat * mediana(RD12/RD_mat)            <- chain-ladder clásico
#   v1      : RD_mat * percentil(hist_dev, (1-rng_p)*100)   CUANTIL ADAPTATIVO
#             rng_p = percentrank_inc(hist_rd, RD_mat), cap 1.0
#   v2      : RD_mat * (fact_autom + mediana) / 2
#   v3      : (v2 + momentum encadenado) / 2
# La idea de v1: si la cohorte viene CALIENTE respecto de su historia (rng_p
# alto), toma un percentil BAJO de los factores de desarrollo; si viene fría,
# uno alto. Es reversión a la media: no multiplica una RD ya alta por un factor
# alto. Parámetros PP_VC: suavizamiento 1.0, percentil_prueba 0.50, cap 1.0.
PROY_METODO = os.environ.get('REE_PROY_METODO', 'v1')       # v1|mediana|v2|v3
# Ventana de cohortes para hist_rd / hist_dev.
# CORRECCION 2026-07-27: era RD_HIST_INI (201901) y estaba MAL. `rng_p` mide a la
# cohorte contra la distribucion historica de RD a esa madurez; si la ventana
# mezcla regimenes, toda cohorte del regimen benigno cae en la cola baja, q=1-rng_p
# se va alto y V1 aplica factores de desarrollo agresivos. Backtest sobre cohortes
# recientes (202401+, madurez 5-10), sesgo medio de V1 por ventana:
#     201901 -> +90.7 bps   (MAE  92.7)   proyectaba 3.830%
#     202201 -> +140.1 bps  (MAE 141.5)   proyectaba 3.955%
#     202301 -> +70.4 bps   (MAE  75.5)   proyectaba 3.310%   (la de BN)
#     202401 -> -1.6 bps    (MAE  46.8)   proyecta   2.990%   <- elegida
# La eleccion NO se justifica por ganar el backtest (seria circular): 202401 es el
# arranque del regimen actual que este mismo config ya declara en REGIME_WINDOWS
# ['reciente'], por una decision anterior e independiente.
# Nota: con ventana homogenea V1 CONVERGE a la mediana (rng_p ~ 0.5 => percentil ~
# mediana). La divergencia grande era artefacto de la ventana, no del metodo.
PROY_VENTANA_INICIO = int(os.environ.get('REE_PROY_VENTANA_INICIO', '202401'))
# Madurez mínima para proyectar. PP_VC original = 3; BN lo forzó a 6 porque solo
# tenía target_06m..12m. Reenganche tiene los 12 horizontes, así que vuelve a 3.
PROY_DEV_START = int(os.environ.get('REE_PROY_DEV_START', '3'))
# Horizonte máximo de proyección, en meses hacia adelante desde COHORTE_FIN.
# Con cierre 202506 y tope 6 -> se proyecta 202507..202512 y se corta 202601.
# OJO, son dos límites DISTINTOS y no coinciden en este corte:
#   meses ADELANTE   = posición de la cohorte tras el cierre   (este parámetro)
#   meses EXTRAPOLADOS = 12 - madurez                          (PROY_DEV_START)
# Con tope 6 adelante entran cohortes de madurez 10..5, o sea hasta 7 meses
# extrapolados. Si lo que se quiere acotar es la EXTRAPOLACIÓN (criterio de BN,
# que usa dev_start=6), subir PROY_DEV_START a 6 en vez de tocar este tope.
PROY_MAX_MESES_ADELANTE = int(os.environ.get('REE_PROY_MAX_MESES', '6'))
PROY_SUAVIZAMIENTO = 1.0
PROY_PERCENTIL_PRUEBA = 0.50
PROY_CAP_RNG = 1.0

# --- Chain-ladder: mínimo cohortes para factor de desarrollo ---
# 3 = mínimo para mediana significativa (práctica actuarial estándar).
MIN_COHORTS_DEV_FACTOR = 3

# --- Entidades ---
IBK_CODE = '00002'
