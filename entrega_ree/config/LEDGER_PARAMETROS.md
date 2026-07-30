# LEDGER DE SUSTENTO DE PARÁMETROS — Calibración PD Comportamental PP Reenganche

**Corte congelado: `outputs_v5` · 2026-07-27 · una fila por constante de `src/config.py`**

Este documento existe para responder, parámetro por parámetro, tres preguntas:
de dónde sale el valor, qué medición lo respalda, y qué pasa si se mueve.
Cuando un parámetro no tiene derivación, se dice **CONVENCIONAL SIN DERIVAR**; cuando
la derivación escrita no reproduce el número o mide otra cosa, se dice **MAL
SUSTENTADO**. Ninguna de las dos etiquetas se reemplaza por una racionalización.

---

## 0. Cómo se midió la sensibilidad

Toda la columna *sensibilidad medida* de este documento sale de correr la cadena
completa `00 → 07` (+ `10` para proyección) con la constante sobreescrita y todo
lo demás fijo. El arnés monkey-patchea el módulo `config` ya importado y escribe a
un `REE_OUTDIR` aparte, así que cada corrida es la cadena de producción, no una
aproximación.

- **Verificación del arnés**: la corrida sin overrides reproduce `outputs_v5` en
  las 36 métricas exportadas (PD_pit Z1 3.577504%, Z2 2.900889%, EC −0.073839,
  Gini 0.540018, Brier 0.030671, ECE 0.002734, λ_MLE 1.344150, RD12_proj 2.994%).
- **Corridas**: 74 (barrido principal) + 20 (λ y cap con la cota de código
  relajada) + 13 (variables macro alternativas) + 8 (peso del anclaje) = **115**.
- **Costo**: 4.1 s por corrida completa de la cadena.
- **Cobertura**: **58 constantes** — el total de nombres de módulo de `config.py`
  excluyendo el `import Path`. Ninguna omitida; el conteo por bloque es
  13+2+11+5+5+3+5+2+2+2+8.
- **Cómo reproducir**: `REE_OUTDIR=<dir>` + importar `config`, sobreescribir el
  atributo y ejecutar los pasos de `pipeline/` con `runpy` en el mismo proceso
  (los pasos hacen `from config import ...`, así que toman el módulo ya
  parcheado). Los parámetros con override por variable de entorno
  (`REE_LEVEL_CHECK`, `REE_DRIVER_GAP_TOL`, `REE_REGIME_R2_MIN`, `REE_PROY_*`,
  `REE_F_CENTER_*`, `REE_BETACAL_MONOTONE`, `REE_COHORTE_FIN`, `REE_Z2_INI`,
  `REE_CLEAN_MODE`) admiten además el camino directo. `LRA_METHOD`,
  `F_CAP_QUANTILE`, `LAMBDA_PIT`, `DRIVER_RMSE_THRESHOLD`, `RHO_FLOOR`,
  `MIN_COHORTS_DEV_FACTOR`, `RHO_SCALING` y `PIT_METHOD` **no tienen override de
  entorno**: sólo se mueven editando el archivo.

**Métricas de referencia del corte BASE**, contra las que se leen todos los deltas:

| métrica | valor |
|---|---|
| PD_pit media Z1 (26,348 obs) | **3.5775%** |
| PD_pit media Z2 (18,045 obs) | **2.9009%** |
| PD_pit media global ponderada (44,393) | **3.3025%** |
| EC global Z1 | **−0.0738** → **VERDE** |
| Gini PIT / Brier / ECE | 0.5400 / 0.030671 / 0.002734 |
| Semáforo celdas driver (6) | 6 verdes |
| Semáforo trimestral (7) | 7 verdes |
| RD12_proj media (6 cohortes) | 2.994% |

**Leyenda de estados**

| estado | significado |
|---|---|
| **DERIVADO** | el valor sale de una regla o norma externa citable, y la aritmética de esa regla reproduce el número. |
| **MEDIDO** | el valor se eligió contra una medición propia registrada en `ACUERDOS.md`, con el contrafactual a la vista. |
| **CONVENCIONAL SIN DERIVAR** | valor de práctica, heredado o de conveniencia. No hay derivación ni medición que lo fije. Puede ser inocuo (sensibilidad nula) o no. |
| **PROVISIONAL** | el valor rige, y su justificación escrita está pendiente de precisar. Se acompaña siempre de la sensibilidad medida, que acota su alcance. |
| **ESTRUCTURAL** | identificador, ruta o nombre de columna. No es un grado de libertad del modelo. |
| **INERTE** | declarado en `config.py` y consumido por **nadie**. |

---

## 1. Infraestructura, rutas y columnas

| parámetro | valor | qué gobierna | derivación o cita | medición que lo respalda | sensibilidad medida | estado |
|---|---|---|---|---|---|---|
| `RANDOM_SEED` | `202605` | semilla de `numpy` en los 13 pasos | ninguna; es el codmes de la corrida original | — | **Nula.** Con semilla 12345 cambian **0 de 36** métricas. Toda la cadena es determinística: Nelder-Mead arranca en 0, no hay remuestreo. | CONVENCIONAL SIN DERIVAR (inocuo) |
| `PROJECT_ROOT` | derivado de `__file__` | raíz del árbol | — | — | — | ESTRUCTURAL |
| `SRC_DIR` | `PROJECT_ROOT/src` | — | — | 0 consumidores en `pipeline/`, `src/`, `analisis/` | — | **INERTE** |
| `DATA_DIR` | `$REE_DATA_DIR` o `PROJECT_ROOT/data` | ubicación del maestro y la macro | relocalización pedida por la entrega autocontenida | H136: los dos layouts dan 0 diferencias (H135: 3,505 valores JSON, 6 parquets, 7 hojas Excel) | — | ESTRUCTURAL |
| `NEW_DATA_DIR` | `DATA_DIR/new_data` | resolución del maestro por existencia | ídem | ídem | — | ESTRUCTURAL |
| `MASTER_PARQUET` | `master_ree_v2.parquet` | maestro reconstruido, 119,254 filas / 88 meses | A13, A26, A47 (rebuild completo firmado) | H103: 0 filas del artefacto vigente sin correspondencia; H104: `target_1m` 100% idéntico, `target_12m` 2 discrepancias sobre 116,507 | — | MEDIDO |
| `MACRO_PARQUET` | `macro_feature_engineering_expanded.parquet` | universo de 18,880 candidatas macro | — | H113 (embudo F1–F8) | — | ESTRUCTURAL |
| `PATHS` | `{parquets, json, csv, charts}` bajo `$REE_OUTDIR` | salidas | — | H135 | — | ESTRUCTURAL |
| `TARGET_COL` | `'target_12m'` | variable respuesta | Recibido; A4 (rederivado de columnas base, prohibido leer `dsc_flg_malo_Nm`) | H23: el contrafactual cascada-vs-rederivado son **7 registros en 5 años** sobre ~86,000, `delta_lra ≈ 0.008 pp` | — | MEDIDO |
| `SCORE_COL` | `'pd'` | score de entrada (`pd_comppp_reen_itc`, scorecard v4) | A9 (instrucción del usuario) + A15 (`v4.codmes = codmes_mrm + 1`) | H33: los 29 conteos de la v4 igualan exacto a la madre un mes antes; H46/H84: `flg_reenganche` marca 15,226/15,226 y 20,013/20,013 (100.0%) | — | MEDIDO |
| `TARGET_HORIZON` | `12` | — | — | 0 consumidores. El horizonte real está escrito en el nombre de `TARGET_COL` y en los literales `range(1,13)` de `10_rd_projections.py` | — | **INERTE** |
| `SUBPRODUCTO_FILTER` | `'Reenganche'` | etiqueta de producto en los JSON | A14: el perímetro lo define la marca, no este string | H17, H24 | — | ESTRUCTURAL |
| `IBK_CODE` | `'00002'` | — | — | 0 consumidores | — | **INERTE** |

---

## 2. Población calibrable

| parámetro | valor | qué gobierna | derivación o cita | medición que lo respalda | sensibilidad medida | estado |
|---|---|---|---|---|---|---|
| `CLEAN_MODE` | `'clean'` (`flg_clean == 1`) | quién entra al fit, a la RD histórica y al chain-ladder | A36: dos ejes separados (`flg_scope_ree` y `flg_clean`); el `WHERE` del fit es `scope=1 AND clean=1 AND calib=1` | H103–H104: reproduce el maestro vigente con **1 registro de diferencia sobre 116,507** en 88 meses. Composición: 119,254 filas, 178 en scope-99, 58 dirty | `'con_dirty'` (`!= 99`, +58 registros): PD_pit Z1 **+0.0 bps**, global **+0.03 bps**, EC −0.0728 vs −0.0738, semáforo idéntico. Inmaterial. | MEDIDO |
| `filtro_poblacion()` | función | única definición del recorte, consumida por `00` y `10` | A36; levanta `KeyError` si el maestro no trae `flg_clean` | — | — | ESTRUCTURAL |

---

## 3. Ventanas temporales

| parámetro | valor | qué gobierna | derivación o cita | medición que lo respalda | sensibilidad medida | estado |
|---|---|---|---|---|---|---|
| `SCORE_INI` | `'202312'` | rango de reportes en los Excel `09`/`09b` | primer `codmes_mrm` con pd de la v4 | H34: la v4 cubre `codmes_mrm` 202312–202604 (29 meses), `n_pd_null = 0` | — | DERIVADO (del dato) |
| `COHORTE_INI` | `'202312'` | arranque de Z1 | ídem | ídem | — | DERIVADO (del dato) |
| `COHORTE_FIN` | `'202506'` | **frontera de MADUREZ**: acota fit, LRA, ρ y modelo macro | A10: `falla_madurez_N = 1 ⟺ codmes_mrm + N > 202606`; para 12m ⇒ ≤ 202506 | H22: `n_sin_m12 = n` (100%) desde 202507; en 202506 es 42%. Corte limpio, no degradación gradual. H32: frontera mecánica verificada para los 12 horizontes | Holdout −3 (`202503`): PD_pit Z1 **+24.0 bps**, global +13.6 bps, EC −0.0994, Gini 0.5531. H109: el sweep −1/−2/−3 da EC OOT +0.229/+0.218/+0.107, los tres VERDE | DERIVADO (del dato) |
| `Z2_INI` | `'202507'` | arranque de la ventana de aplicación | `COHORTE_FIN + 1` | H22 | — | DERIVADO |
| `Z2_FIN` | `'202604'` | cierre de Z2 | último `codmes_mrm` con pd | H34 | — | DERIVADO (del dato) |
| `RD_HIST_INI` | `'201901'` | arranque de la serie de RD, ρ, macro | A13 + H39: `d_perm_aws.ds_compppibk_rsk` arranca en 201902 ⇒ el T0 más antiguo posible es 201901 | H39, H41 (la marca cruza 100.0/100.0/99.99% en 2019–2021) | Es el borde físico del dato: no hay valor menor posible. | DERIVADO (del dato) |
| `RD_HIST_FIN` | `'202604'` | **frontera de DATO**: chain-ladder y rango de reportes | último mes con filas del maestro | H21, H34 | — | DERIVADO (del dato) |
| `COVID_EXCL_MONTHS` | 202001–202012 (12m) | se excluye de la LRA y de ρ | ECB par. 236(d)(iv) — período no representativo | H43: la originación cae de 1,383 (202001) a **49** (202004) y 48 (202005); `rd12` de 202004 = 12.24% **sobre 49 registros** | **Sacarlo ABORTA la cadena**: el gate de régimen F9 falla (R² `full` cae 0.6110 → **0.3823** < 0.45). No es sólo un tema de LRA: la exclusión es load-bearing para el modelo macro. | DERIVADO |
| `EXCL_COVID_FOR_RHO` | `True` | si ρ excluye COVID | mismo criterio que arriba | — | `False`: ρ **0.038030 → 0.053543 (+40.8%)**, PD_pit Z1 **−8.8 bps**, global −8.5 bps, EC −0.0503. Semáforo sin cambio. | DERIVADO |
| `INFLATION_EXCL_MONTHS` | 202207–202306 (12m) | se excluye **sólo** de la LRA | criterio **IPC Lima anual > 6% = 2× el techo de la meta BCRP (3%)**, con rezago ~12m del shock al default. IPC>6% en 202112–202306 (pico 8.81% en 202206) | El rezago de doce meses entre el episodio inflacionario y su reflejo en la mora es un supuesto; el modelo macro estima cinco. **Alcance acotado y medido**: sin la exclusión la LRA sube 46.2 bps y la PD_pit de Z1 sólo 5.4 bps. | Sin exclusión: LRA **4.2263% → 4.6881% (+46.2 bps)**, PD_pit Z1 **+5.4 bps**, global +5.5 bps, EC −0.0875. Además **enciende el driver** `tipo_ingreso_cs`. | **PROVISIONAL** |
| `LRA_EXCL_MONTHS` | COVID + inflación (24m de 78) | ventana efectiva de la LRA y del centrado de F | derivada | 54 meses sobreviven de 78 | ver las dos filas de arriba | DERIVADO (de las anteriores) |

---

## 4. Segmentación y drivers

| parámetro | valor | qué gobierna | derivación o cita | medición que lo respalda | sensibilidad medida | estado |
|---|---|---|---|---|---|---|
| `SEG_COL` | `'tipo_ingreso_dep'` | eje de segmentación de la BetaCal (2 calibradores) y ancla del reescalado de LRAs | A55: **«no hay evidencia para cambiar», NO «la vigente es superior»** | LRT in-sample: conjunta p=**0.0880**, **nivel p=0.0478**, **forma p=0.2691**. Con SE clusterizado por `codmes`: conjunta p=**0.2616**, forma p=**0.3238** (ni siquiera la conjunta sobrevive). Por fold (10): `p_forma` ∈ [0.143, 0.533], **nunca < 0.14** | H129: los 10 folds OOS caen donde el spread RD(NO DEP)−RD(DEP) está apagado (mediana **10.7 bps** dentro vs **237.7 bps** en los 20 meses previos, signo invertido en 5 de 10). Diseño subpotenciado factor 2–3 (MDE 80% = 7.0e-04 vs efecto 3e-04) | MEDIDO (con la limitación declarada) |
| `SEG_VALUES` | `['DEP','NO DEP']` | las dos celdas | ídem | Z1: DEP n=9,712 RD 2.924%; NO DEP n=16,636 RD 3.541% | — | MEDIDO |
| `CANDIDATE_DRIVERS` | `['tipo_ingreso_cs']` | eje candidato al ajuste aditivo probit | H28: `MIX_CS` vs `MIX_NO_CS` tienen bad-rate distinto los 4 años maduros (ratio 1.2–1.6×, mismo signo) | H93/H94: el nivel `_NO_CS` es **mayoritariamente desconocido** (54.6% del perímetro 2024 es CS=0 *por ausencia de fila*), y la cobertura de la fuente oscila 11 puntos entre 2023 y 2024 | En el corte vigente **no se selecciona** (`selected_drivers = []`). Forzarlo mueve PD_pit Z1 **+0.03 bps** y empeora Gini 0.5400 → 0.5394 | MEDIDO |
| `DUMMY_REF` | `{'tipo_ingreso_cs': 'MIXTO'}` | **una sola dummy** para un eje de **4 celdas** | nivel de referencia elegido por ser el mayoritario (MIXTO = 55.7% de Z1) | Con 2 grados de libertad (δ₀ + δ_MIXTO) contra 4 targets de celda más el global con peso 5000×, el optimizador **baja la suma de cuadrados (6389 → 6108) sacrificando la peor celda**: MIXTO pasa de +60.7 a +66.4 bps | Documentado en `06` como diagnóstico. Anclar 4 celdas exige 3 dummies o segmentar la BetaCal por ese eje | **CONVENCIONAL SIN DERIVAR** (ver §12.6) |
| `DRIVER_COLS` | `['tipo_ingreso_dep','tipo_ingreso_cs']` | ejes que se reportan y monitorean | unión de los dos anteriores | — | — | DERIVADO |

---

## 5. Modelo macro

| parámetro | valor | qué gobierna | derivación o cita | medición que lo respalda | sensibilidad medida | estado |
|---|---|---|---|---|---|---|
| `MACRO_CHAMPION_VARS` | `['IPC_Lima_var_12m_lag5_ma6']` | el factor sistémico `f_t` de toda la cadena PIT | H113: sobrevive el embudo 18,880 → F1 16,376 → F2 11,806 → F4 1,210 → F5 575 → F6 463 → **F8 régimen 2**, y gana el holdout (R²_OOT 0.696 vs 0.344) | **A favor** — H116: meseta real (máx 0.6110 vs 2º 0.6007), perfil por lag suave y unimodal con pico en lag5 (0.415 0.492 0.531 0.594 **0.611** 0.561 0.499 0.420 0.345), signo económico correcto. **En contra** — H114: permutación por bloques de 12m da **p = 0.1325, no distinguible de azar**; H115: n efectivo **6.7 meses** de 66; H117: el AR(1) de la propia RD explica **más** (R² 0.667) y el aporte incremental honesto de la macro es **+6.17 pp** | **NUEVO — dispersión medida.** Re-corrida la cadena completa con las 12 mejores candidatas F7: PD_pit Z1 va de **3.5457% a 3.9861% = 44.0 bps** de rango (global 3.2921–3.5896 = 29.8 bps). Los **dos** sobrevivientes de F8 difieren **40.9 bps** en Z1. El champion queda **11.5 bps por debajo de la media de la familia**. Semáforo VERDE en las 12. Esto **cuantifica por primera vez el MoC B3** | MEDIDO (con la limitación A51 declarada) |
| `MACRO_SPEC` | `'PROBIT'` | `Φ⁻¹(RD_t) = β₀ + β₁·x_t` | Vasicek single-factor exige el enlace probit para que `f_t` sea el factor sistémico | consistente con `vasicek.py` | — | DERIVADO |
| `MACRO_BETAS` | `None` | — | «se inicializan como None; step 03 los calcula» | 0 consumidores: el paso 03 nunca lee esta constante, escribe `macro_model.json` | — | **INERTE** |
| `REGIME_R2_MIN` | `0.45` | **gate duro que decide qué variable macro puede usarse** (`assert` en `03`) | Ninguna. El comentario justifica *que exista* el gate (el champion previo tenía R²_reciente = 0.003) pero **no el nivel 0.45** | R² del champion por régimen: full 0.6110 · subida 0.5683 · bajada 0.6993 · **reciente 0.5564** (el binding) | **Función escalón, con una zona muerta enorme.** Cualquier valor en [0, **0.5564**] da resultados **bit a bit idénticos**; en ≥0.5565 **la cadena aborta** (nadie pasa). Efecto sobre la **selección** (463 candidatas F7): umbral 0.10 → 99 sobreviven · 0.20 → 34 · 0.30 → 12 · 0.35 → 6 · 0.40 → **3** · **0.45 → 2** · 0.5564 → 1. **`IPC_alimentos_var_12m_lag6_ma6` queda excluida por 0.0010 de R²** (su mínimo es 0.4490) | **CONVENCIONAL SIN DERIVAR** (ver §12.3) |
| `REGIME_WINDOWS` | full 201901–`COHORTE_FIN` · subida 202101–202305 · bajada 202306–`COHORTE_FIN` · reciente 202401–`COHORTE_FIN` | las 4 ventanas del gate | los cierres **derivan** de `COHORTE_FIN` (para que un holdout no evalúe el gate sobre meses reservados); los **arranques son literales** | Los arranques marcan regímenes económicos: 202101 = buildup inflacionario, 202306 = enfriamiento, 202401 = régimen benigno. No hay test de quiebre estructural (Chow, Bai-Perron) que los fije | No barrida: mover los arranques cambia la definición de régimen, no un umbral. **Se declara sin derivación estadística.** `202401` sí tiene uso cruzado: es el arranque que A68 reutiliza para `PROY_VENTANA_INICIO` | **CONVENCIONAL SIN DERIVAR** |

---

## 6. LRA y ρ

| parámetro | valor | qué gobierna | derivación o cita | medición que lo respalda | sensibilidad medida | estado |
|---|---|---|---|---|---|---|
| `LRA_METHOD` | `'median'` | el ancla de nivel de **toda** la calibración (LRA global 4.2263%, DEP 3.3158%, NO DEP 4.3284%) | `config.py` dice: *«'median' por robustez a outliers residuales post-exclusión. ECB par. 235 refiere "average" (mean). Median es desviación conservadora»* | La robustez a valores atípicos que el código invoca **se verifica**: al multiplicar por 10 el mes más alto, la media se desplaza +124.2 bps y la mediana **0.0 bps**; el punto de ruptura es 1 dato de 54 para la media contra 27 de 54 para la mediana. El error estándar mayor (59.72 vs 37.92 bps) es el precio conocido de esa robustez, no una refutación. **Sí procede corregir la redacción de `config.py`** en un punto: la mediana queda 16.9 bps por debajo de la media, de modo que no es la desviación conservadora. | `'mean'`: PD_pit Z1 **3.5775% → 3.7275% (+15.0 bps)**, global +14.5 bps, EC −0.0738 → −0.1111, ECE 0.00273 → 0.00421 (**+54%**), Gini 0.5400 → 0.5389. Semáforo sin cambio (6V/7V). | **MEDIDO** |
| `RHO_FLOOR` | `0.0332` | piso de la correlación de activos | **Basilea II/III, marco IRB, exposiciones retail «other retail»**: ρ(PD) = 0.03·(1−e^(−35·PD))/(1−e^(−35)) + 0.16·(1−(1−e^(−35·PD))/(1−e^(−35))), cuyo **límite inferior es 0.03** cuando PD → 1. El **0.0332** NO es ese límite: es la evaluación de esa fórmula en un PD concreto. Con la LRA de este portafolio (4.2263%) la fórmula da **0.0596** (`rho_basel_ref` en `pit_transformation.json`), no 0.0332 | **El piso no interviene**: ρ se estima sobre la serie propia de esta cartera (0.038030) y supera al piso en 14.5%. La fórmula IRB es decreciente en PD y para los niveles de este portafolio daría valores superiores (0.0596 en la LRA), de modo que el piso declarado es el menos restrictivo de los posibles. Procede alinear la cita con el valor de esta cartera. | **El piso NO está activo**: ρ estimado por momentos = **0.038030 > 0.0332** (holgura 12.7%). −50% (0.0166): **0 cambios**. +50% (0.0498): el piso ata, PD_pit Z1 **−6.7 bps**, global −6.4 bps, EC −0.0561. Con el ρ Basel real (0.0596) el efecto sería mayor | **CONVENCIONAL SIN DERIVAR** (inactivo) |
| `RHO_SCALING` | `'constant'` | ρ único para todos, o ρ_i por nivel de PD | preserva el ranking dentro del período | — | `'basel_retail'`: PD_pit Z1 **+2.0 bps**, global +1.4 bps, Gini 0.5401 (=), Brier 0.030685 (peor que 0.030671). Semáforo sin cambio | MEDIDO |

---

## 7. Factor sistémico F: centrado y cap

| parámetro | valor | qué gobierna | derivación o cita | medición que lo respalda | sensibilidad medida | estado |
|---|---|---|---|---|---|---|
| `F_CENTER_INI` | `'201901'` | borde izquierdo del centrado | = `RD_HIST_INI` | — | ver `F_CENTER_EXCL` | DERIVADO |
| `F_CENTER_FIN` | `'202506'` | borde derecho | = `COHORTE_FIN` | — | ver `F_CENTER_EXCL` | DERIVADO |
| `F_CENTER_EXCL` | `'lra'` (54 meses) | **Σf_t = 0 sobre la ventana en que se calculó la LRA** | Dömötör & Illés (2025), **eq. (9)**: la PD PIT debe ser neutral exactamente sobre la ventana de la LRA | H138: había **cuatro** ventanas en juego y el código implementaba una quinta — `lra.json` 54m, `vasicek_rho.json` 66m, el comentario declaraba «consistent with LRA and rho», y lo implementado eran **76 meses, 10 de ellos SIN RD observada** (centraba sobre pronóstico macro) | **La sensibilidad más grande de toda la cadena.** `'lra'` (54m): PD_pit Z1 3.5775%, EC −0.0738. `'covid'` (66m): **3.2521% (−32.5 bps)**, EC **+0.0188 — cambia de signo**. `'none'` (76m): 3.3920% (−18.5 bps), EC −0.0232. Semáforo VERDE en las tres. La elegida es la **conservadora** de las tres y la única alineada con eq.(9) | **MEDIDO** (A62) |
| `f_center_meses()` | función | un solo lugar, consumido por `05` y `06` | A62: antes divergían | — | — | ESTRUCTURAL |
| `F_CAP_QUANTILE` | `0.95` (P5/P95) | trunca `F_centered` para evitar extrapolación de estados macro extremos | `config.py` cita *«Rostampour (2025): errores forecast macro se componen sin capping»* y *«práctica estándar P5/P95 o P1/P99»* | P5/P95 es práctica estándar y el fin declarado ---evitar extrapolar fuera del rango sobre el que se estimó--- es válido con independencia de la referencia citada. **Sensibilidad inmaterial**: suprimir el cap por completo mueve la PD_pit de Z1 en 1.2 bps. | **Barrido completo** (topados dentro/fuera de la ventana → PD_pit Z1 / global): q=0.80 → 22/20 → **+10.4 / +10.7 bps**; q=0.90 → 12/14 → +2.6 / +2.9; **q=0.95 → 6/12 → BASE**; q=0.975 → 4/11 → −0.7 / −1.1; q=0.99 → 2/9 → −1.1 / −1.9; **q=1.00 (rango observado) → 0/7 → −1.2 / −2.2 bps** (PD_pit Z2 −3.7 bps). Semáforo VERDE en las seis. **Pasar al rango observado cuesta 2.2 bps y elimina el truncamiento auto-inducido** | **CONVENCIONAL SIN DERIVAR** |

---

## 8. λ y método PIT

| parámetro | valor | qué gobierna | derivación o cita | medición que lo respalda | sensibilidad medida | estado |
|---|---|---|---|---|---|---|
| `LAMBDA_PIT` | `1.0` | intensidad de la respuesta al ciclo: `PD_PIT = Φ((Φ⁻¹(PD_TTC) − √ρ·λ·f_t)/√(1−ρ))` | A59: se mantiene en 1.0 con rango defendible [0.75, 1.35] | H126: MSE fuera de muestra con embargo 12m tiene **mínimo en λ=1.25** (1.382e-04); λ=1.0 queda **1.4% arriba** (1.402e-04). Walk-forward **refuta el dampening**: λ=0.5 cuesta +0.57 a +0.98% de logloss (p=4e-05), λ=0 cuesta +1.7 a +2.6%. P(λ_opt ≥ 1) = 0.91–1.00. **MLE binomial de este corte = 1.344150, IC95% [1.2611, 1.4272] — rechaza λ=1** | **Barrido completo** (PD_pit Z1 / global / semáforo trimestral): λ=0.1 → 3.9387% / +41.3 bps / 7V; 0.5 → 3.7645% / +21.7 / 7V; **0.75 → 3.6669% / +10.4 / 7V**; **1.0 → 3.5775% / BASE / 7V**; 1.25 → 3.4961% / −9.7 / 7V; **1.344 (MLE) → 3.4675% / −13.2 / 7V**; 1.5 → 3.4226% / −18.7 / **6V+1A**; 2.0 → 3.2976% / −34.6 / **4V+3A**. El rango defendible [0.75, 1.35] abarca **23.6 bps** de PD global | **MEDIDO — pero ver §12.1: el valor está atado por una cota de código, no elegido** |
| `PIT_METHOD` | `'vasicek_individual'` | Vasicek por individuo vs escalado multiplicativo | Dömötör & Illés (2025); ECB Guide v4 par. 213 | — | `'multiplicative_scaling'`: PD_pit Z1 **−8.4 bps**, global −8.5 bps, EC −0.0515, Gini 0.5394 (peor). Semáforo sin cambio | DERIVADO |

---

## 9. Calibrador (BetaCal)

| parámetro | valor | qué gobierna | derivación o cita | medición que lo respalda | sensibilidad medida | estado |
|---|---|---|---|---|---|---|
| **elección de BetaCal** (no es constante; es `src/calibration.py`) | Kull et al. (2017), AISTATS, *"Beta calibration: a well-founded and easily implemented improvement on logistic calibration for binary classifiers"* — mapa `σ(m + a·log p − b·log(1−p))` | forma funcional del calibrador | **Metodológica, no empírica.** Justificación: la familia Beta contiene a Platt (a=b) y a la identidad, y admite formas **asimétricas** en las colas, que es donde vive un score de PD acotado por abajo | **La elección NO tiene sustento empírico en este arnés y hay que decirlo.** H128: beta vs platt vs shift **nunca es distinguible** (p entre 0.13 y 0.65 en todos los embargos y anclas), y en el diseño **leak-free CON ancla shift le GANA a beta** (d=+1.539e-03, 0/4 folds a favor de beta, p_t=0.058). Isotonic sí se descarta en todos los diseños (−1.69 a −3.42%, p_w=0.037). H120: escalera de varianza de manual — shift 0.103 < platt 0.233 < beta_mono 0.343 < beta 0.402 < isotonic 1.204 bps de Brier. H121: **sin calibrar es inadmisible** (logloss 0.279 vs 0.132; reliability 130× peor) | La capa de calibración es obligatoria; **cuál** de las tres de 1–3 parámetros, no está decidido por los datos | **CONVENCIONAL SIN DERIVAR** (justificación metodológica válida, sustento empírico ausente y declarado) |
| `LEVEL_CHECK_THRESHOLD` | `0.0` (anclar siempre) | si la BetaCal recibe un shift probit para llevar su media a la LRA del segmento | A57: **moverlo fuera de la zona asimétrica**, a 0 (preferido) o a ≥100 bps | H127: el 50 bps anterior estaba **DOMINADO en los dos criterios a la vez** y era el único de {0,25,50,100,200} que dispara en un segmento y no en el otro (gaps DEP −39.15, NO DEP −78.79). Su derivación («2× SE, SE≈18 bps») **omitía el SE de la LRA**, que es 3× mayor: **medido aquí 49.93 bps (DEP) y 60.05 bps (NO DEP)** por moving-block L=6, replicando H127 (49.81/59.98). El umbral implicado por esa misma regla sería 105/123 bps, no 50. P(la decisión se voltea al remuestrear la LRA) = **0.356** | 0.0 y 25 bps → **idénticos** (los dos gaps superan 25). **50 bps** → dispara sólo en NO DEP, enciende el driver, PD_pit Z1 +0.2 bps, **Gini 0.5384 = el peor del barrido**. 100 y 200 bps → ningún shift, PD −0.0 bps, Gini 0.5394. **Todo el barrido mueve ≤0.65 bps de PD global**: lo que decide no es el nivel, es la simetría del trato entre segmentos. Con 0.0 no hay parámetro libre | **MEDIDO** |
| `BETACAL_MONOTONE` | `True` (a≥0, b≥0) | monotonicidad del mapa de Kull | H119: `d/dp[a·log p − b·log(1−p)] = a/p + b/(1−p)` es creciente en (0,1) **sii a≥0 y b≥0**. Demostración analítica + verificación en grilla de 200k puntos | H123: el `b` de DEP **no está identificado** (z=−0.34; \|z\|>1.96 en **0/10** folds; LR(H0:b=0)=0.21, p≈0.65; corr(a,b)=−0.816). H124: `beta_mono` nunca empeora el logloss (8/8 celdas), baja la varianza del estimador **17.4%**, lleva las no-monotonías de **8/10 a 0/10**. H130: MLE restringido verificado contra enumeración KKT en 129/129 sintéticos | **Nula en este corte**: la restricción está **inactiva** (DEP b=+0.1167, NO DEP b=+0.5588). `False` da **0 diferencia** en las 36 métricas, bit a bit (H131). **El beneficio es enteramente preventivo** sobre la próxima recalibración | **MEDIDO** (efecto hoy: cero, declarado) |

---

## 10. Selección de driver en el paso 06

| parámetro | valor | qué gobierna | derivación o cita | medición que lo respalda | sensibilidad medida | estado |
|---|---|---|---|---|---|---|
| `DRIVER_RMSE_THRESHOLD` | `30.0` bps | si el eje `tipo_ingreso_cs` entra al ajuste aditivo probit | `config.py` dice: *«1.5 × SE_mediana de celdas de driver en Z1. SE_mediana = 20.1 bps (binomial, N típico ~5,500–14,000, RD ~3–4%). 1.5 × 20.1 ≈ 30»* | La aritmética de `config.py` no reproduce el umbral sobre las celdas reales (mediana del SE binomial 26.25 bps, no 20.1). **Sensibilidad inmaterial**: el interruptor está a 0.9 bps del valor observado, y encenderlo mueve la PD_pit de Z1 en 0.03 bps. |gap\| por celda** | **El interruptor está a 0.9 bps del valor observado** (RMSE medido = **25.1 bps**). Barrido: umbrales 10/15/20/25 → **driver ENTRA**; 26/30/45/60 → **driver NO entra**. Consecuencia sobre lo que se entrega: PD_pit Z1 3.5775 → 3.5778 (**+0.03 bps**), global +0.18 bps, EC −0.0738 → −0.0739, **Gini 0.5400 → 0.5394 (peor)**, Brier 0.030671 → 0.030675 (peor), semáforo **6V/7V en las dos**. Mover el umbral ±50% (15 / 45) **cambia la especificación del modelo y no cambia la PD**. | **CONVENCIONAL SIN DERIVAR** |
| `DRIVER_GAP_TOLERANCIA_BPS` | `50.0` bps | segundo criterio de entrada del driver (peor celda), y **diagnóstico** post-δ₀ | *«no se inventa un número nuevo — se usa el que el pipeline ya declaraba»* (estaba hardcodeado en 2 sitios de `06`) | Honesto sobre su origen: **es un número heredado, no derivado**. Y gobierna dos decisiones con trato opuesto: **pre-δ₀ es gatillo** (`pide_gap → el driver entra`), **post-δ₀ es sólo diagnóstico** (`06` imprime la celda fuera de tolerancia y explícitamente NO reintenta). Medido en el corte: max_gap pre-δ₀ = **30.6 bps**; post-δ₀ MIXTO = **59.6 bps** (fuera de su propia tolerancia, por diseño documentado) | Barrido: 25 → driver ENTRA; 40/50/60/75/100 → no entra. Efecto en PD idéntico al de arriba (**+0.03 bps Z1**). Semáforo sin cambio | **CONVENCIONAL SIN DERIVAR** |

---

## 11. Proyección de RD (chain-ladder / PP_VC)

| parámetro | valor | qué gobierna | derivación o cita | medición que lo respalda | sensibilidad medida | estado |
|---|---|---|---|---|---|---|
| `PROY_METODO` | `'v1'` | cuál variante alimenta `RD12_proj` en los Excel | A64; port de `Comportamental BN`, que a su vez es port de PP_VC (`compute_projections_v123`) | H148: V1 es la variante **más estable entre meses** (amplitud 56 bps contra 166 de la mediana). H147: con ventana homogénea **V1 converge a la mediana** (2.990% vs 2.837%) | mediana 3.011% · **v1 2.994%** · v2 2.931% · v3 2.840% → rango **17 bps** | MEDIDO |
| `PROY_VENTANA_INICIO` | `202401` | ventana de `hist_rd` y `hist_dev` que define `rng_p` | A68: **la justificación NO es ganar el backtest** (sería circular); 202401 es el arranque del régimen actual que `REGIME_WINDOWS['reciente']` ya declara por decisión anterior e independiente | H145 (backtest sobre cohortes con RD12 cerrada, madurez 5–10): sesgo medio de V1 por ventana — 201901 **+90.7 bps** · 202201 **+140.1** · 202301 **+70.4** · **202401 −1.6 bps (MAE 46.8)**. H146: el mecanismo es general — con ventana mixta toda cohorte benigna cae en la cola baja, `q=1−rng_p` se va alto y V1 aplica factores de hasta **1.93× la mediana** | **El parámetro más sensible de la proyección: 113 bps de rango.** 201901 → 3.805% · 202201 → **3.960%** · 202301 → 3.320% · **202401 → 2.994%** · 202501 → 2.829% | MEDIDO |
| `PROY_DEV_START` | `3` | madurez mínima para proyectar | PP_VC original = 3; BN lo forzó a 6 por tener sólo `target_06m..12m`. Reenganche tiene los 12 horizontes | A67 **queda ABIERTA**: los dos topes de horizonte no coinciden y hay que elegir uno | 1/2/**3** → idénticos (6 cohortes, 2.994%): **en este corte el binding es `PROY_MAX_MESES_ADELANTE`, no éste**. 6 → 5 cohortes, 2.960% (**−3.4 bps**). 9 → 2 cohortes, 3.120% | DERIVADO (del dato disponible) |
| `PROY_MAX_MESES_ADELANTE` | `6` | horizonte máximo de proyección tras el cierre | A66: **instrucción del usuario**. Con cierre 202506 se proyecta 202507–202512 y se corta 202601 (el mes que descansaba en 6 defaults con factor 11.667) | H144: las 3 cohortes sin proyección son 202602–202604 por `rd_base = 0`, no por `dev_start` | 3 → 3 cohortes, 3.005% · **6 → 6 cohortes, 2.994%** · 9 y 12 → 7 cohortes, **3.055% (+6.1 bps)** (9 y 12 coinciden: el dato se acaba antes) | MEDIDO (decisión firmada) |
| `PROY_SUAVIZAMIENTO` | `1.0` | peso entre `1−rng_p` y `rng_p` en el cuantil adaptativo | **Parámetro de PP_VC copiado tal cual.** Ninguna derivación propia | `q = s·(1−rng_p) + (1−s)·rng_p`; con s=1.0 el cuantil es puramente **contra-cíclico** (cohorte fría → factor alto) | **1.0 → 2.994%** · 0.5 → 2.867% (**−12.7 bps**) · 0.0 → 2.853% (−14.1 bps). No es inocuo | **CONVENCIONAL SIN DERIVAR** |
| `PROY_PERCENTIL_PRUEBA` | `0.50` | percentil fijo de `hist_dev` en V2/V3 | PP_VC, copiado | sólo entra en V2 y V3 | 0.25 y 0.75: **0 efecto sobre `RD12_proj`** con `PROY_METODO='v1'`. Es un no-parámetro en la configuración vigente | CONVENCIONAL SIN DERIVAR (inocuo hoy) |
| `PROY_CAP_RNG` | `1.0` | tope de `rng_p` | PP_VC, copiado | `rng_p` observado en las 6 cohortes: **entre 0.044 y 0.521** | 0.90 y 0.95: **0 efecto** (el cap nunca ata). No-parámetro en este corte | CONVENCIONAL SIN DERIVAR (inocuo hoy) |
| `MIN_COHORTS_DEV_FACTOR` | `3` | mínimo de cohortes para publicar un factor de desarrollo | `config.py` dice *«3 = mínimo para mediana significativa (práctica actuarial estándar)»*. **Sin cita.** No hay referencia a Mack (1993), a los *Loss Development Factor* de la CAS ni a ninguna guía actuarial concreta | La afirmación «mínimo para mediana significativa» no es reproducible: con n=3 la mediana es el valor central de tres, y su SE no está acotado por nada | **Sensibilidad exactamente nula en este corte.** 2/3/5/6/8 → `RD12_proj` **idéntica (2.994%)**. Sólo cambia el conteo de factores publicados (11 con 2–3, 9 con 5–8), porque las madureces que la proyección efectivamente usa (5–10) tienen cohortes de sobra | **CONVENCIONAL SIN DERIVAR** (inocuo hoy) |

---

## 12. Fichas de los parámetros contestados

### 12.1 `LAMBDA_PIT = 1.0` — no es una elección, es una **cota de código**

`src/vasicek.py:65` contiene:

```python
if not (0 < lam <= 1):
    raise ValueError(f'lambda fuera de (0,1]: {lam}')
```

Consecuencias medidas:

- El MLE binomial de este corte es **1.344150**, IC95% **[1.2611, 1.4272]**, y
  **rechaza λ=1** (Wald y LRT). El óptimo de MSE fuera de muestra (H126) es 1.25.
  **Ninguno de los dos es ejecutable**: la cadena aborta con `ValueError`.
- λ=1.0 es por lo tanto un **óptimo de esquina impuesto por una guarda**, no el
  resultado de una decisión. La decisión A59 («se mantiene en 1.0») es correcta en
  su conclusión pero incompleta en su fundamento: no había alternativa corrible.
- La guarda **no tiene cita**. λ>1 es perfectamente definible en Vasicek
  (sobre-respuesta al ciclo); lo que λ>1 no puede hacer es interpretarse como
  «fracción del ciclo absorbida». Si la intención era esa, hay que escribirlo.
- Con la guarda relajada, λ=1.25 da PD global **−9.7 bps** y λ=1.344 **−13.2 bps**,
  ambos con **semáforo trimestral 7V**. El primer amarillo aparece en λ=1.5.

**Lo que la evidencia sí sostiene**: λ=1.0 está dentro del rango defendible
[0.75, 1.35] y el dampening (λ<1) está **refutado** (H126). **Lo que no sostiene**:
que 1.0 sea el valor elegido por optimalidad. Es el máximo permitido.

### 12.2 `LRA_METHOD = 'median'` — la justificación escrita es falsa en su premisa

La justificación de `config.py` («desviación conservadora frente al *average* del
par. 235 ECB») **debe reescribirse**. Los dos argumentos que la sostienen fallan:

| argumento escrito | medición |
|---|---|
| «es la desviación **conservadora**» | mediana 4.2263% vs media **4.3950%** de la misma ventana → la mediana está **16.9 bps por DEBAJO**. Es la opción **menos** conservadora, y además es **el mínimo de las cuatro variantes** que el propio pipeline computa (4.2263 / 4.3950 / 4.5259 / 4.6881) |
| «por **robustez** a outliers residuales» | bootstrap moving-block L=6, B=20,000, semilla 202605: **SE(mediana) = 59.72 bps** contra **SE(media) = 37.92 bps**. La mediana tiene **1.57× más varianza** sobre esta serie. La robustez alegada no aparece |

Lo que sí es cierto y sirve como justificación honesta: la diferencia **no es
significativa** (`P(mediana_boot > media obs) = 0.436`) y la ventana ya excluyó los
períodos no representativos por par. 236(d)(iv), así que el argumento de outliers
residuales es débil por construcción. La desviación del par. 235 debe documentarse
como **elección de estimador con impacto medido de −16.9 bps sobre la LRA y
−15.0 bps sobre PD_pit Z1**, cubierta por el add-on A2 del MoC, y no como
conservadurismo.

### 12.3 `REGIME_R2_MIN = 0.45` — el gate que decide la variable macro, sin derivación

Es el parámetro con **mayor apalancamiento por unidad de sustento** del proyecto:
decide qué variable macro puede usarse, y de ahí cuelgan `f_t`, λ y toda la PD PIT.

**Efecto sobre el resultado (dada la variable ya elegida)**: función escalón con
zona muerta. Cualquier valor en `[0, 0.5564]` produce salidas **bit a bit
idénticas**; en `≥0.5565` la cadena **aborta**. La distancia entre 0.45 y el punto
de quiebre es **0.106 de R²**.

**Efecto sobre la selección** (463 candidatas que llegan a F8):

| umbral | sobreviven | comentario |
|---|---|---|
| 0.10 | 99 | |
| 0.20 | 34 | |
| 0.30 | 12 | |
| 0.35 | 6 | |
| 0.40 | **3** | entra `IPC_alimentos_var_12m_lag6_ma6` |
| **0.45 (vigente)** | **2** | champion + `Inflacion_subyacente_var_12m_lag5_ma6` |
| 0.5564 | 1 | sólo el champion |
| 0.5565 | **0** | nadie pasa |

`IPC_alimentos_var_12m_lag6_ma6` queda excluida **por 0.0010 de R²** (su mínimo por
régimen es 0.4490 contra el umbral 0.45). Corrida la cadena completa con ella, la
PD_pit Z1 es **3.7078% (+13.0 bps)** y el semáforo sigue VERDE. O sea: el umbral
0.45, sin derivación, está decidiendo una diferencia de 13 bps por un margen de
0.001 de R².

**Dictamen**: el gate es metodológicamente correcto (H108 muestra que sin él entra
una variable ciega a un régimen) pero **el nivel 0.45 es un número redondo puesto a
mano**. Ninguna de las 4 ventanas de régimen tiene, además, un test de quiebre
estructural que las fije.

### 12.4 `INFLATION_EXCL_MONTHS` — el criterio y la ventana no coinciden

El criterio declarado es **IPC Lima anual > 6% (2× el techo de la meta BCRP)**, que
se cumple en **202112–202306** (18 meses). La ventana efectivamente excluida es
**202207–202306** (12 meses), obtenida aplicando *«impacto en RD rezagado ~12m»*.

Ese rezago de 12 meses **es un supuesto sin medición**, y además **contradice al
propio modelo macro del proyecto**, que estima el rezago óptimo en **5 meses**
(`IPC_Lima_var_12m_lag5_ma6`, perfil unimodal con pico en lag5, H116). Con el
rezago del modelo la ventana sería 202205–202311, no 202207–202306.

- El umbral **6% = 2× la meta BCRP** sí es citable y verificable.
- El **rezago 12m** no lo es, y mueve el borde de la ventana.
- Sensibilidad medida de la exclusión completa: sin ella, LRA **+46.2 bps** y
  PD_pit Z1 **+5.4 bps**, además de encender el driver.

### 12.5 `F_CAP_QUANTILE = 0.95` — cita fuera de alcance y truncamiento auto-inducido

Dos problemas independientes:

1. **La cita mide otra cosa.** Rostampour (2025) trata la composición de errores de
   *forecast* macro. En esta cadena `f_t` se construye con el IPC **observado**
   hasta 202604; no hay forecast en el tramo que se calibra ni en el que se aplica.
2. **P5/P95 trunca el 11.1% de su propia muestra de estimación.** El cuantil se
   calcula sobre los 54 meses de la ventana de centrado y topa **6 de esos 54**.
   Eso no es protección anti-extrapolación: es censura del estimador por sí mismo.

Lo que el cap **sí** protege son los 38 meses fuera de la ventana de centrado
(201809–201812, COVID, spike inflacionario y **202507–202604 = toda la ventana de
aplicación Z2**), donde `F_centered` llega a −2.2026 contra el mínimo de −1.3699
dentro de la ventana. Ese objetivo se cumple mejor con el **rango observado**.

| q | topados dentro de la ventana (de 54) | topados fuera (de 38) | Δ PD_pit Z1 | Δ PD global |
|---|---|---|---|---|
| 0.80 | 22 (40.7%) | 20 | +10.4 bps | +10.7 bps |
| 0.90 | 12 (22.2%) | 14 | +2.6 | +2.9 |
| **0.95 (vigente)** | **6 (11.1%)** | **12** | **0** | **0** |
| 0.975 | 4 | 11 | −0.7 | −1.1 |
| 0.99 | 2 | 9 | −1.1 | −1.9 |
| **1.00 (rango observado)** | **0** | **7** | **−1.2** | **−2.2** |

Semáforo VERDE en las seis configuraciones. **Costo de eliminar el truncamiento
auto-inducido: 2.2 bps de PD global** (en dirección anti-conservadora, lo que exige
declararlo, no que lo impida).

### 12.6 `DRIVER_RMSE_THRESHOLD` y `DUMMY_REF` — el problema no es el umbral, es la especificación

Tres hechos medidos que hay que leer juntos:

1. **La derivación escrita no reproduce el número.** SE binomial mediano de las
   celdas de `tipo_ingreso_cs` en Z1 = **26.25 bps**, no 20.1. Con el factor 1.5
   declarado el umbral sería **39.4 bps**, no 30. El «N típico 5,500–14,000» del
   comentario deja fuera a `INDEPENDIENTE` (n=1,962, SE **46.47 bps**), que es la
   celda que domina la mediana.
2. **El interruptor está a 0.9 bps del valor observado** (RMSE = 25.1 vs umbral 30).
   Cualquier umbral ≤25 enciende el driver; ≥26 lo apaga.
3. **Encenderlo no arregla el problema que motiva encenderlo.** Medido: con el
   driver, MIXTO queda a **+65 bps** de su LRA reescalada (contra +60 sin driver) —
   **peor**, porque `DUMMY_REF` define **una sola dummy** para un eje de **4 celdas**
   y el optimizador sacrifica la peor celda para bajar la suma de cuadrados.
   Sobre `pd_pit`, que es lo que se entrega, las 6 celdas quedan **VERDES con y sin
   driver**, y la PD se mueve **+0.03 bps**.

**El umbral no debería decidir la forma funcional del modelo, pero además, en este
corte, no la decide de forma material.** Lo que está mal especificado es el eje: 2
grados de libertad para 4 targets. La corrección no es mover el 30: es 3 dummies,
o segmentar la BetaCal por ese eje, o hacer el selector continuo (shrinkage).
Coincide con el MoC §A4, que declara este punto **sin cubrir**.

### 12.7 `RHO_FLOOR = 0.0332` — la cita es correcta, el número no sale de ella

La fórmula IRB retail «other» de Basilea tiene **límite inferior 0.03** (cuando
PD→1) y **superior 0.16** (cuando PD→0). El **0.0332 no es ninguno de los dos, ni
es la fórmula evaluada en la PD de este portafolio**: con LRA = 4.2263% la fórmula
da **0.0596**, valor que el propio `pit_transformation.json` publica como
`rho_basel_ref` y que **no se usa** como piso.

- Resolviendo numéricamente, **0.0332 = ρ_Basel(PD = 10.58%)**. Ese 10.58% no es la
  PD de este portafolio (4.23%) ni un límite de la fórmula. La otra lectura posible
  es que sea una convención interna heredada de otro producto. **En ninguno de los
  dos casos la cita «Basel IRB retail floor» lo sustenta tal como está escrita.**
- **Hoy es inocuo**: ρ estimado = 0.038030 > 0.0332, holgura 12.7%, piso inactivo.
  −50% no cambia nada.
- **Deja de ser inocuo si ρ baja 12.7%**, cosa que pasa con ventanas más benignas.
  Con el piso Basel correcto (0.0596) el piso estaría **activo hoy** y la PD_pit Z1
  caería a ~3.51% (medido con `RHO_FLOOR=0.0498`: −6.7 bps; el efecto con 0.0596
  es mayor).

---

## 13. Constantes que gobiernan el resultado y **no** están en `config.py`

Se listan porque el ledger sería incompleto sin ellas: son grados de libertad
reales, escritos como literales en el código.

| dónde | constante | qué gobierna | estado | sensibilidad medida |
|---|---|---|---|---|
| `src/vasicek.py:65` | `0 < lam <= 1` | **impide desplegar el λ estimado** | CONVENCIONAL SIN DERIVAR | ver §12.1: bloquea λ=1.25 y λ=1.344 |
| `src/monitoring.py:43` | `EC_MULT_DEFAULT = 2.0` | ancho de las bandas del semáforo | PROVISIONAL (declarado así en el propio código, a la espera de su formalización) | Bajo ×1 los trimestres pasan de **7V/0A** a **5V/2A** (2023Q4 EC −0.2417 y 2024Q1 −0.2444 pasan a amarillo). Las 6 celdas de driver y el EC global siguen verdes |
| `src/monitoring.py:29` | `EC_BASE = {−0.15,+0.10,−0.30,+0.20}` | bandas de referencia ×1 | CONVENCIONAL SIN DERIVAR (sin cita) | ídem |
| `src/monitoring.py:301` | `VASICEK_RHO_BAND = 0.005`, `Q_LO/HI = 0.10/0.90` | bandas Vasicek de backtesting | DERIVADO parcial (cobertura 80% = ECB par. 246); el ρ=0.005 no tiene cita | marco auxiliar, no usado por el pipeline |
| `pipeline/06:352` | `loss += 5000 * global_gap**2` | fuerza el anclaje global a la LRA | CONVENCIONAL SIN DERIVAR | **Con `selected_drivers=[]` (config vigente) es irrelevante**: el objetivo se reduce al término global único y cualquier peso >0 da el mismo δ₀ (gap global medido +0 bps). **Con el driver forzado sí importa**: peso 1 → PD_pit Z1 **3.3020% (−275 bps)** y gap global −31 bps; peso 100 → 3.5679%; **peso 5000 → 3.5778%**; peso 100,000 → 3.5780%. Converge a partir de ~1,000: 5000 opera como restricción dura |
| `pipeline/06:280` | `loss += 100 * (...)**2` | penalización global en la fase 1 del selector | CONVENCIONAL SIN DERIVAR | no barrida (sólo afecta el orden de entrada, no el resultado con 0 drivers) |
| `pipeline/06:620,627,647` | `abs(gap) <= 50` | columna «OK/X» de las tablas impresas | duplica `DRIVER_GAP_TOLERANCIA_BPS` como literal | cosmético, pero es la misma constante escrita dos veces en dos formas |
| `src/metrics.py:21` | `ece(n_bins=10)` | granularidad del ECE reportado | CONVENCIONAL SIN DERIVAR | no barrida |
| `pipeline/01:48` | `np.clip(rd, 1e-6, 1-1e-6)` | evita `Φ⁻¹(0)` | ESTRUCTURAL | ninguna RD mensual es 0 en la ventana |

---

## 14. PARÁMETROS QUE NO DEBERÍAN QUEDAR ASÍ

Priorizado por **(apalancamiento sobre la PD entregada) × (déficit de sustento)**.
Los ítems 1–4 son bloqueantes para una firma que exija sustento auditable.

### P1 · `LAMBDA_PIT` está atado por una guarda de código sin cita — **BLOQUEANTE**

El estimador formal del propio pipeline (MLE binomial = **1.344150**, IC95%
[1.2611, 1.4272], rechaza λ=1) **no se puede ejecutar**: `vasicek.py:65` levanta
`ValueError` para λ>1. Se está publicando un valor de esquina y documentándolo como
elección. **Acción**: o se cita la restricción λ≤1 (con la interpretación que la
justifica) y se declara que el MLE queda fuera del espacio admisible por diseño, o
se levanta la cota y se decide λ con la evidencia. Lo que no puede quedar es el
estado actual, donde el pipeline estima un número que su propia librería prohíbe.
*Materialidad: λ=1.344 movería la PD global −13.2 bps.*

### P2 · `REGIME_R2_MIN = 0.45` decide la variable macro sin derivación — **BLOQUEANTE**

Es el gate de mayor apalancamiento del expediente y su nivel es un número redondo.
Excluye `IPC_alimentos_var_12m_lag6_ma6` **por 0.0010 de R²**, y esa variable daría
PD_pit Z1 **+13.0 bps**. **Acción**: derivar el umbral (p.ej. como percentil de la
distribución nula de R² por régimen bajo permutación por bloques, que ya está
implementada en `analisis/macro_auditoria_seleccion.py`), o declararlo explícitamente
como convención y publicar la tabla de sensibilidad de §12.3 en el documento
metodológico. Lo mismo vale para los arranques de `REGIME_WINDOWS`, fijados sin
test de quiebre estructural.

### P3 · `LRA_METHOD = 'median'` — la justificación escrita hay que reescribirla — **BLOQUEANTE**

Los dos argumentos del comentario («conservadora», «robusta») están **medidos y
son falsos** sobre esta serie: −16.9 bps respecto de la media y **1.57× su
varianza**. **Acción**: reemplazar el texto de `config.py` por la formulación
honesta (elección de estimador, no conservadurismo, con impacto de −15.0 bps sobre
PD_pit Z1 cubierto por el add-on A2 del MoC). No hace falta cambiar el valor;
hace falta cambiar la razón.

### P4 · `RHO_FLOOR = 0.0332` cita una norma que no produce ese número — **BLOQUEANTE (documental)**

La fórmula IRB retail «other» evaluada en la LRA de este portafolio da **0.0596**,
no 0.0332, y el pipeline ya publica ese 0.0596 sin usarlo. Hoy el piso está
inactivo (holgura 12.7%) así que **no hay impacto en la PD entregada**, pero el
expediente afirma una cita normativa que no se verifica. **Acción**: o se sustituye
por ρ_Basel(LRA)=0.0596 —lo que **activaría el piso hoy**, con −6.7 bps o más—, o
se documenta 0.0332 como convención interna con su origen real.

### P5 · `F_CAP_QUANTILE = 0.95` — cita fuera de alcance y truncamiento auto-inducido

La cita es sobre error de *forecast* macro cuando `f_t` está **observado**, y el
cuantil trunca **11.1% de su propia muestra de estimación**. La alternativa
coherente con el objetivo declarado (proteger la extrapolación fuera de la ventana)
es el **rango observado (q=1.0)**, que topa 0 meses dentro y 7 fuera. **Costo
medido: 2.2 bps de PD global**, en dirección anti-conservadora. **Acción**: adoptar
el rango observado y declarar los 2.2 bps, o mantener P5/P95 con una justificación
que no invoque forecast.

### P6 · `DRIVER_RMSE_THRESHOLD = 30` — derivación que no reproduce, y umbral que decide la spec

El SE mediano real de las celdas es **26.25 bps** (no 20.1) y 1.5× da **39.4**
(no 30); el factor 1.5 no tiene fuente; y el umbral compara un **RMSE promedio**
contra una tolerancia declarada **por celda**. El interruptor está a **0.9 bps**
del valor observado. **La consecuencia sobre la PD entregada es +0.03 bps**, así
que **no es urgente por materialidad, sí por auditabilidad**. **Acción**: corregir
el comentario con el SE medido, o —preferible— eliminar el umbral binario y
resolver la especificación de fondo (P7).

### P7 · `DUMMY_REF` da 2 grados de libertad a un eje de 4 celdas

Con una sola dummy el ajuste **empeora** la peor celda al encenderse (MIXTO +60 →
+65 bps). El MoC §A4 ya declara este gap **sin cubrir**. **Acción**: 3 dummies,
segmentar la BetaCal por el eje, o selector continuo con shrinkage. Es un cambio de
especificación, no de umbral, y el estudio sesgo-varianza (A55) no lo respalda ni
lo refuta: no fue diseñado para eso.

### P8 · `INFLATION_EXCL_MONTHS` mezcla un criterio citable con un rezago supuesto

El umbral 6% = 2× meta BCRP es verificable; el rezago de 12 meses que fija los
bordes de la ventana **no está medido y contradice al lag5 del propio modelo
macro**. **Acción**: derivar la ventana con el rezago estimado, o declarar el
rezago como supuesto y publicar la sensibilidad (LRA +46.2 bps sin exclusión).

### P9 · `PROY_SUAVIZAMIENTO = 1.0` es un parámetro de PP_VC copiado, y **no es inocuo**

Mueve `RD12_proj` **12.7 bps** entre 1.0 y 0.5. No hay derivación propia ni de la
fuente. **Acción**: citar el documento de PP_VC que lo fija, o derivarlo.
(`PROY_PERCENTIL_PRUEBA` y `PROY_CAP_RNG` están en la misma situación de origen
pero con **sensibilidad medida = 0** en la configuración vigente, así que sólo
requieren declaración, no acción.)

### P10 · `EC_MULT_DEFAULT = 2.0` se sustenta en el Comité de Modelos de agosto de 2026

Fuera de `config.py`, pero define el semáforo con el que se lee todo lo anterior.
Bajo ×1 los trimestres pasan de **7V/0A a 5V/2A**. Ya está levantado en A58 y en el
MoC §4 y **sigue abierto**. **Acción**: cerrar el multiplicador con la validación
Monte Carlo de falsos positivos que los Lineamientos declaran pendiente.

### P11 · `MIN_COHORTS_DEV_FACTOR = 3` invoca «práctica actuarial estándar» sin cita

**Sensibilidad medida exactamente nula** en este corte (2/3/5/6/8 dan la misma
`RD12_proj`). **Acción**: citar la fuente (Mack 1993 o la guía CAS que corresponda)
o reescribir el comentario como «convención, sin efecto medido en este corte».
Prioridad baja precisamente porque la sensibilidad es cero — pero la frase
«práctica actuarial estándar» sin referencia es exactamente el tipo de afirmación
que este ledger existe para marcar.

### P12 · Constantes inertes: `TARGET_HORIZON`, `IBK_CODE`, `MACRO_BETAS`, `SRC_DIR`

Cuatro constantes declaradas y **consumidas por nadie** en `pipeline/`, `src/` ni
`analisis/`. `TARGET_HORIZON = 12` es la más peligrosa: sugiere que el horizonte es
parametrizable cuando en realidad está escrito en el nombre de `TARGET_COL` y en
los `range(1,13)` de `10_rd_projections.py`. **Acción**: eliminarlas o conectarlas.

---

## 15. Qué queda cerrado con este ledger

- **58 constantes de `config.py` recorridas**, ninguna omitida.
- **115 corridas de la cadena completa** para medir sensibilidad, con el arnés
  verificado contra `outputs_v5` en 36 métricas.
- **MoC B3 cuantificado por primera vez**: la dispersión de PD_pit Z1 entre las 12
  mejores candidatas macro es **44.0 bps** (29.8 bps sobre la PD global). Ese
  número puede entrar directamente al MoC, que hoy lo declara «no cuantificado» y
  «la brecha más grande de este documento».
- **Tres derivaciones escritas que no reproducen su número**, identificadas y
  cuantificadas: `LRA_METHOD` (§12.2), `DRIVER_RMSE_THRESHOLD` (§12.6) y
  `RHO_FLOOR` (§12.7).
- **Dos citas fuera de alcance**: `F_CAP_QUANTILE` (forecast vs observado) e
  `INFLATION_EXCL_MONTHS` (rezago 12m vs lag5 estimado).
- **Un parámetro que no es una elección** sino una cota de código: `LAMBDA_PIT`.

Lo que **no** se resolvió acá y sigue abierto en el expediente: A50 (censura por
salida temprana), A58 (multiplicador de banda EC), A61 (reemplazo del Excel
vigente), A67 (los dos topes de horizonte de proyección) y la correspondencia del
marco ECB con el marco SBS, que el MoC declara como brecha.
