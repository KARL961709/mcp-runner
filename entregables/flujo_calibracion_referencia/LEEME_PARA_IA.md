# Flujo de calibración PD — artefacto de referencia

Brief para la IA que implemente este flujo en otra máquina. Léelo completo antes de tocar nada.
Todo lo que está aquí fue simulado y probado fuera del banco contra las calibraciones desplegadas;
lo único no probado es el SQL corriendo en Athena (ver §9).

---

## 1. Qué se quiere

MLOps pidió que las constantes del `inference.sql` de calibración salgan de **una tabla de parámetros
gobernada** por Calibración (owner: Carlos Acosta Tapia · steward: Carlos Enrique Ñaupari Lavalle).
El diseño final separa por completo modelo y calibración:

- **Modelo** (no se toca): `ds_<modelo>` → pkl CatBoost → `scr_<modelo>_rsk` con la PD raw.
- **Calibración**: 3 tablas + 1 pkl de parámetros + 2 motores.

| Paso | Pieza | Qué es |
|---|---|---|
| 0 | `scr_<modelo>_rsk` | Salida del modelo: PD raw (`prob_modelo`, `puntuacion`) + `woe_<variable>` |
| 1 | `inference.sql` → `t_cal_<modelo>_rsk` | Arma el ds: PD raw, x macro del mes y x congelada, drivers y flags |
| 2 | pkl de parámetros (`objeto_calibracion.pkl`) | SOLO DATOS: método TTC por celda, anclas, forma+coef+topes del f_t, ρ, λ, sufijo por producto, versión |
| 3 | `inference.py` → `scr_cal_<modelo>_rsk` | Lee ds + pkl y CALCULA: TTC, f_t, PIT, freeze, puntuaciones |
| — | `t_cal_parametros_rsk` | Una sola tabla para TODOS los modelos. Hoy un único parámetro: `cod_mes_freeze` |

El diagrama entidad-relación completo está en `docs/estructuras_calibracion.html` (abrir en navegador;
tiene botones para bajar PNG/SVG/Excel con las 3 tablas). El deck con el AS-IS vs TO-BE está en
`docs/propuesta_calibracion_der.html`.

## 2. Contenido del paquete

```
LEEME_PARA_IA.md                 este documento
docs/                            diagrama ER y deck (HTML)
ddl/                             CREATE TABLE de las tablas (placeholders <base_cal>, <bucket>)
sql/                             inference.sql de t_cal: REE (cppibkren) y VC (vcadmbnk) — PLANTILLAS
mlops/scripts/inference.py       job de calibración (MLOps): ds + pkl -> scr_cal
mlops/scripts/utils/calculo.py   funciones TTC, f_t, PIT, freeze, controles del pkl
pkl/spec_<id_calibracion>.json   parámetros de cada calibración (REE v1, VC v2/v3/v4)
pkl/armar_pkl.py                 JSON -> objeto_calibracion.pkl
denton/generar_pesos.py          genera t_mst_denton_pesos_rsk.csv (y se autoprueba)
referencia/sql_referencia.py     implementación de REFERENCIA del inference.sql (Python, probada)
referencia/*.parquet / *.csv     ds y scr esperados, porc_ipc público (BCRP), tabla de parámetros
pruebas/probar_todo.py           prueba autónoma: debe dar 26/26
```

Requisitos: Python 3.10+, `numpy`, `pandas`, `scipy`, `pyarrow`.

**Primer paso obligatorio:** `python pruebas/probar_todo.py` desde la raíz. Si no da 26/26, no sigas.

## 3. Las estructuras (no agregar ni quitar campos sin OK del owner)

### `t_cal_parametros_rsk` (6 campos) — `ddl/01`
`modelo` · `parametro` · `valor` (string) · `nro_carga` · `ts_carga` · `p_codmes` (partición = mes desde el que rige).
Llave: `modelo + parametro + nro_carga + p_codmes`. **Solo se agregan filas; nunca se editan ni borran.**
Vigencia para un `cod_mes`: mayor `p_codmes ≤ cod_mes` del modelo y, dentro, mayor `nro_carga`
(`nro_carga` se cuenta POR MODELO). Para reconstruir qué carga usó una corrida pasada: además `ts_carga ≤ ts_carga del scr`.

### `t_cal_<modelo>_rsk` = ds (37 campos) — `ddl/02`
Llaves · `prob_modelo`, `puntuacion` (NEW) · `var_macro_01..12` · `var_driver_01..12` · `flg_clean_01..04` · `ts_carga` · `p_codmes`, `p_fecdia`.
**var_macro guarda la x (macro TRANSFORMADA), nunca el f_t.** Dos columnas por variable:
`var_macro_{2k-1}` = x del mes, `var_macro_{2k}` = x congelada. Máximo 6 variables.

### pkl de parámetros — `pkl/`
SimpleNamespace (sin clase propia): `modelo`, `id_calibracion` (ej. `cppibkren_202609_v1`), `fecha`, `productos`.
Cada producto: `sufijo` (`_pp`, `_ppfacil`, `_tc`, `_ec`, `_ppcd`… o `EXTRA`), `variables` ([k]),
`modelo_macro` (FT_VASICEK: pd_lra, intercepto, pendientes, media_centrado, topes · LINEAL_CAP: beta, mu, topes · None si TTC)
y `filas` (ESQUEMA, BETA/PLATT/ISOTONICA por celda, ANCLA, VASICEK ρ y λ, CLIP).
Se guarda también como JSON legible (`spec_*.json`): el JSON es la fuente; el pkl se arma con `armar_pkl.py`.

### `scr_cal_<modelo>_rsk` — `ddl/03` (REE) y `ddl/03b` (VC)
6 base (llaves + PD raw) · **8 campos ×N por producto** con sufijo `_<prod>`:
`factor_macro`, `factor_macro_freeze`, `prob_modelo_cal`, `puntuacion_cal`, `prob_modelo_cal_freeze`,
`puntuacion_cal_freeze`, `prob_modelo_cal_smacro`, `puntuacion_cal_smacro` (NEW) ·
`id_calibracion` (NEW) · `extra_01..08` (06–08 NEW: alcanzan para UN producto no planificado, sufijo `EXTRA`) · `p_codmes`, `p_fecdia`.
No lleva `cod_mes_freeze`, `grupo_calibracion` ni PD de estrés (decisión del owner).

### `t_mst_denton_pesos_rsk` — `ddl/04` (tabla nueva, pendiente de OK)
Pesos fijos para la mezcla de fuentes (§5). Se carga desde `denton/t_mst_denton_pesos_rsk.csv`.

## 4. Criterio: qué es parámetro, qué es lógica, qué es modelo

| Valor | Dónde vive | Por qué |
|---|---|---|
| `cod_mes_freeze` | `t_cal_parametros_rsk` | Decisión que cambia sin recalibrar |
| serie, ventana, transformación de x, mezcla de fuentes, escenario BASE | `inference.sql` (lógica) | Cambiarlos es cambiar el modelo |
| reglas de drivers (DEP/NO DEP, nodos, dirty) | `inference.sql` (lógica) | Definen la celda |
| Beta/Platt/tramos, anclas, coef. y topes del f_t, ρ, λ | pkl | Se estiman juntos en la recalibración |
| funciones TTC, f_t, PIT, freeze | `utils/calculo.py` | Código; cambiarlas = cambio de método (MRM) |
| x congelada | ds del mes de freeze | Se LEE de lo ya publicado, no se recalcula ni se tipea |

## 5. La macro y la mezcla de fuentes

Cada ejecución procesa **un solo `cod_mes` t** (MLOps reemplaza `{codmes}`).

- **REE** (`cppibkren`): x(t) = promedio de `porc_ipc` de t-11 a t-6 (exige los 6). Siempre observado.
  f_t = Vasicek probit acotado (coeficientes en el pkl).
- **VC** (`vcadmbnk`): x(t) = MA3 de la inflación a 12 meses compuesta (t-2..t). f_t lineal acotado por producto.
  **Fuentes combinadas**: el observado del BCRP (`e_perm_aws.t_mst_bcrp_rsk.porc_ipc`) SIEMPRE manda.
  Si k meses de la ventana aún no están publicados (k = t − último observado):
  - k = 0 → MA3 del observado.
  - k = 1 o 2 → Denton aditivo de la inflación 12m trimestral de APOYO (`disc_model_owner.macro_apoyo_proy`,
    ticker `AP00025BQ` = BASE, entrega vigente: mayor `p_codmes ≤ t`, mayor `nro_carga`), anclado al observado.
    Athena no resuelve el sistema de Denton, pero la solución es lineal: x(t) = Σ peso × valor, con pesos fijos
    por (variante, fase, k). `fase` = `month(último observado) mod 3`.
  - k ≥ 3 → fuera de diseño: detener.
  Variante por defecto: `SIN_TRIM_CURSO` (el trimestre a medio observar NO se fuerza a promediar APOYO,
  porque eso multiplica por 3 el error de APOYO en el mes proyectado). **Pendiente de decisión del owner.**
- **Freeze**: el SQL busca `cod_mes_freeze` vigente y copia `var_macro_01` del ds de ese mes a `var_macro_02`.
  Si `cod_mes_freeze = t`, usa la x del propio mes. Si no existe el ds del mes de freeze: DETENER.
  (Los reprocesos de meses anteriores al freeze son válidos: lo que se exige es que exista ese ds.)

## 6. Cómo implementar (orden)

1. `python pruebas/probar_todo.py` → 26/26.
2. Crear las tablas con `ddl/` (reemplazar `<base_cal>`, `<bucket>`). Pedir a MLOps las columnas en **double**
   (con `decimal(18,6)` cambian puntuaciones).
3. `python denton/generar_pesos.py` → cargar el CSV en `t_mst_denton_pesos_rsk`.
4. Cargar en `t_cal_parametros_rsk` una fila por modelo (ver `referencia/t_cal_parametros_rsk.csv`).
5. Adaptar `sql/` (placeholders `<base_cal>`, `<base_mlops>`, `<fuente_drivers_vc>`: los drivers del VC se
   copian de su SQL vigente). Correr UN mes y comparar contra `referencia/sql_referencia.py` alimentado con la
   misma serie del banco: la x debe coincidir (tolerancia 1e-12; Athena suma en otro orden).
6. `python pkl/armar_pkl.py pkl/spec_<id>.json <carpeta>` → `objeto_calibracion.pkl` en `models/` del job.
7. Desplegar `mlops/scripts/inference.py` + `utils/calculo.py` (entradas: `DIR_DATA` con `ds.parquet`,
   `DIR_MODELS` con el pkl; salida en `DIR_RESULTS`). No lee la tabla de parámetros.
8. Validar el scr del banco contra el cálculo local (`utils/calculo.py` sobre el mismo ds): debe ser idéntico.

## 7. Operación

| Evento | Qué se hace | Qué NO se toca |
|---|---|---|
| Nuevo freeze | Agregar una fila `cod_mes_freeze` con `p_codmes` = mes desde el que rige | código, pkl, otros modelos |
| Corrección del freeze | Misma partición, `nro_carga` + 1 | la fila anterior (queda como historia) |
| Recalibración | Nuevo `spec_*.json` con otro `id_calibracion` → nuevo pkl → despliegue del artefacto de calibración | código, tabla de parámetros |
| Producto no planificado | En el spec, `sufijo = "EXTRA"` → va a `extra_01..08` como texto exacto (`repr`) | estructura del scr |
| Producto nuevo permanente | Nuevo bloque `_<prod>`: `ALTER TABLE ... ADD COLUMNS` (8 columnas) | — |
| Bivariado | `variables: [1, 2]`, `pendientes`/`beta` con 2 coeficientes; x2 en `var_macro_03/04` | un solo f_t |
| Modelo sin macro | `modelo_macro: null` y sin bloque VASICEK | — |

## 8. Trampas ya pagadas

- `pd.read_csv` por defecto corre el último dígito de ~36% de los floats: usar parquet o `float_precision='round_trip'`.
- Athena: un statement por archivo, sin `;` (ni en comentarios), sin BOM; los CTE NO se materializan.
- La copia local de `porc_ipc` (`referencia/porc_ipc_bcrp.csv`) trae 202611 y 202612, que al 2026-11-12 no
  estaban publicados: no tratarlos como observados. Usar SIEMPRE la serie del banco.
- REE: la x congelada del banco es `0.5705583377953397` (la copia local da otra). VC: los f_t congelados
  desplegados (TC 0.0332973095 · PP 0.1002652693) corresponden a x ≈ 4.25; al migrar, tomar la x del banco de 202609.
- El REE desplegado suma `(z+δ)+δ0` y aquí `z+(δ+ajuste)`: diferencias de 1 ulp (≤ 2.8e-16) en la PD; puntuaciones idénticas.
- Nunca poner identificadores de cliente en queries o archivos que salgan del banco. Los ejemplos usan
  `DOC_EJEMPLO` / `CLI_EJEMPLO` y llaves inventadas.

## 9. Estado

**Probado** (fuera del banco): REE y VC desplegados reproducidos (PD ≤ 2.8e-16, puntuaciones exactas, VC bit a bit
con 3 versiones de pkl); freeze por fila; vigencia con 40 modelos; recalibración por pkl; extras; bivariado; TTC;
el job se detiene ante errores; Denton por pesos = solución exacta.

**No probado:** el SQL en Athena; la serie real del banco; los drivers del VC en el SQL nuevo.

**Pendiente de decisión:** campos NEW con MLOps (`prob_modelo`/`puntuacion` en ds; `id_calibracion`,
`puntuacion_cal_smacro`, `extra_06..08` en scr_cal); bloque por producto `_<prod>` en vez de 3 grupos fijos;
`modelo` y `ts_carga` de control en scr_cal; tabla nueva de pesos Denton; variante Denton del trimestre en curso.
