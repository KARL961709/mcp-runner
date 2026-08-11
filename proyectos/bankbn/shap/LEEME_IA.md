# Brief para la IA de la maquina de ejecucion

Esta carpeta se corre **en la PC del banco** (la que tiene acceso a AWS). La maquina
de origen no lo tiene, por eso el trabajo se parte en dos.

**Esta maquina hace `git pull`, nunca `git push`.** El canal de vuelta es una persona
copiando texto. Diseña para un solo viaje.

---

## Que se busca

Se esta calibrando la PD de Origen Bank BPE. Campanas reclama que la PD sale muy
conservadora y recorta leads, sobre todo en la poblacion **SSFF** (clientes que no
son del top 4 de bancos). Ya se midio que el SSFF tiene PD 13.15% contra 5.60% de
IBK, y que **31 de 38 variables del modelo son monotonas IBK -> RESTO_TOP4 -> SSFF**,
o sea la poblacion esta genuinamente ordenada.

Lo que falta es **atribuir esa brecha variable por variable con TreeSHAP**, y separar:

- cuanto viene de **riesgo real observable** (RCC, SENTINEL: comportamiento de pago)
- cuanto viene de **informacion que el SSFF no puede tener** (PASIVOS-IBK, TRX-IBK,
  ADEX, SUNARP, SUNAT). Ahi el modelo penaliza ausencia de dato, no presencia de
  riesgo, y eso es lo que decidiria si corresponde una re-ancla propia para no-Top-4.

Hay una duda abierta que el script resuelve en su primer paso, y **de esa duda depende
que todo lo demas sirva**: las columnas de la tabla de score se llaman `woe_*`, y al
contrastar sus medias contra los umbrales de corte del artefacto, **10 de 38 caen
fuera del rango**. Tres son imposibles (un conteo de entidades con media negativa,
una cantidad de vehiculos de -0.14). O las `woe_*` no son los inputs del modelo, o
el artefacto disponible es de otra version. El paso 1 lo decide midiendo, no opinando.

---

## Requisitos

1. **El parquet** de `disc_model_owner.ds_adm_bpe_shap_muestra`, creado por
   `proyectos/bankbn/sql_prod/f4_export/95_shap_muestra.sql`.
   Son hasta 72,000 filas (3 poblaciones x 24 codmes x 1,000), sin `key_value` ni
   `tip_doc`. Si no esta descargado todavia, ver "Como generarlo" abajo.

2. **El artefacto** `model_ligthbm_admbank.sav` — el LightGBM de admision Bank BPE,
   4,000 arboles, 39 features. Viene del paquete de MLOps del modelo.
   **No esta en el repo y no debe subirse.**

3. Python con `pandas`, `numpy`, `pyarrow`, `lightgbm`. No hace falta el paquete
   `shap`: LightGBM trae TreeSHAP adentro via `booster.predict(X, pred_contrib=True)`.

---

## Como generarlo (si el parquet aun no esta)

```
.\Go.ps1 -SqlDir proyectos/bankbn/sql_prod/f4_export -Only 94_reset_shap_muestra
.\Go.ps1 -SqlDir proyectos/bankbn/sql_prod/f4_export -Only 95_shap_muestra -S3Datos "s3://<bucket>/<prefijo>/shap" -Bajar
```

Dos cosas que ya costaron un viaje:

- **`0 filas` en ambos es correcto y esperado.** `Run-Athena.ps1:177` fuerza
  `$lineas = 0` para todo lo que empiece en `CREATE|DROP|ALTER|INSERT|MSCK`, porque
  un CTAS no devuelve result set. No es sintoma de nada.
- **`-S3Datos` tiene que apuntar a un prefijo nuevo y vacio.** El `-Bajar` hace
  `aws s3 sync` de *todo* el prefijo: si lo apuntas a uno que ya tiene otros
  exports, te baja todo de nuevo. La tabla es externa, asi que un `DROP` tampoco
  limpia S3 — por eso el `external_location` va versionado (`shap_v1/`).

---

## Que correr

```
python shap_muestra.py <carpeta_o_ruta_del_parquet> <ruta>\model_ligthbm_admbank.sav
```

El script imprime tres bloques y **el primero condiciona a los otros dos**:

**PASO 1 — test de escala.** Aplica el artefacto a las columnas `woe_*` y las compara
contra la columna `probabilidad`, que ya viene calculada en la tabla de score.
Tres desenlaces posibles, y el script dice cual:

| resultado | lectura |
|---|---|
| `max abs(dif) < 1e-6` | las `woe_*` SON los inputs. La atribucion de los pasos 2 y 3 es exacta. |
| no reproduce pero `corr > 0.99` | el artefacto es de otra version. SHAP sirve para el ORDEN, no para el nivel. |
| no reproduce y `corr` baja | las `woe_*` no son los inputs de este artefacto. Los pasos 2 y 3 **no deben reportarse como atribucion del modelo en produccion**. |

**PASO 2** — descomposicion IBK vs RESTO_TOP4 vs SSFF en log-odds, reponderada por
`n_estrato` (la muestra es 1,000 por estrato y los estratos son de tamano muy
desigual: sin reponderar, las medias mienten).

**PASO 3** — que variables mueven la PD de IBK desde 202603, contra la ventana
202507-202602.

---

## Que devolver

**Pega de vuelta la salida completa de consola del script** (son unas 60 lineas) y el
contenido de `outputs/shap_ibk_vs_ssff.csv` (39 filas: variable, shap_ibk, shap_ssff,
delta, fuente, pct_brecha).

Eso es agregado por variable y no lleva identificadores.

**No devuelvas** el parquet, ni filas individuales, ni muestras de registros. Si algo
falla y necesitas mas para diagnosticar, pide un mensaje de error mas explicito — no
una muestra de filas. La regla del repo es: el codigo entra, los datos no salen.

---

## Si algo no cuadra

Reportalo en vez de arreglarlo por tu cuenta. En particular:

- si el parquet trae menos de ~40,000 filas, o alguna poblacion falta
- si `n_estrato` viene nulo o en 1 para todo (romperia la reponderacion)
- si faltan columnas: el script las lista y corta solo
- si el paso 1 no reproduce: **eso es un hallazgo, no un error**. Reportalo tal cual
  con los numeros, es exactamente lo que se esta tratando de averiguar.
