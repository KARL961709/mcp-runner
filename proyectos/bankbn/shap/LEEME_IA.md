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

## De donde sale cada cosa

El parquet es el join de dos tablas, hecho por `95_shap_muestra.sql`:

| tabla | que aporta |
|---|---|
| `e_perm_aws.scr_admbankbpe_rsk` | **la tabla de score del banco.** De aca salen las 39 columnas `woe_*` y la columna **`probabilidad`, que es la PD que el modelo ya calculo en produccion.** Particionada por `p_codmes`. |
| `disc_model_owner.ds_adm_bpe_bankbn_cal_202607` | la poblacion de altas y toda la cadena de calibracion: `pd_raw`, `pd_cal`, `rho_i`, `fhat`, `prob_modelo_cal`, `puntuacion_modelo`, `target_12m`, `entidad`, `personeria`, los `flg_`. |

El join es por `tip_doc` + `key_value` + codmes **con desfase de +1 mes**: la partición
`p_codmes` del score corresponde al `codmes` de la alta menos uno. Ese desfase esta
declarado en el SQL pero **no esta cerrado del todo** (`rules_model.json` por su lado
declara +2, y la cobertura del score arrancando en 202206 sugiere +0). Por eso el
script arranca con un PASO 0 que lo verifica gratis.

**La comparacion del PASO 1 se hace contra `probabilidad`, no contra ninguna PD
recalculada.** Es la cifra que ya existe en la tabla de score del banco: si el
artefacto aplicado a las `woe_*` la reproduce, las `woe_*` son los inputs y punto.

**Cheque de coherencia (PASO 0):** `pd_raw` y `probabilidad` deberian ser la misma
cifra por dos caminos distintos. Si difieren, el join esta desfasado y nada de lo que
sigue es leible.

## Las tres poblaciones

Se definen sobre la columna `entidad` de la tabla de calibracion:

| pob | regla | que es |
|---|---|---|
| `IBK` | `entidad = 'IBK'` | el cliente ya tiene la relacion con Interbank |
| `SSFF` | `entidad = 'OTRO'` | fuera del top 4 de bancos. **Es la poblacion en disputa.** |
| `RESTO_TOP4` | cualquier otra | BCP, BBVA, Scotiabank |

## Lo que ya se midio (no hace falta recalcularlo)

PD media: **IBK 5.603% · RESTO_TOP4 8.252% · SSFF 13.154%**.

**31 de 38 variables son monotonas IBK -> RESTO_TOP4 -> SSFF**, cubriendo el 81% del
peso SHAP documentado del modelo. Por azar se esperarian 12.7. La poblacion esta
genuinamente ordenada; no es una variable suelta ni un artefacto de derivacion.

Ratios IBK/SSFF en las variables de fuente que el SSFF **no puede tener**
(pesan 19.5% del modelo entre todas):

| variable en la tabla | nombre en el modelo | fuente | IBK | SSFF |
|---|---|---|---|---|
| `woe_max_dismsldo12rl` | `max_d_sld_12um_rl` | SUNAT | -19,990 | -546 |
| `woe_prm_valorexpimp12m` | `x12_valor__impexp` | ADEX | 8,790 | 252 |
| `woe_min_sldopasi06m` | `min_sldpdvtotal_6um` | **PASIVOS IBK** | 6,345 | 456 |
| `woe_prm_nrotrxcashout06m` | `x6_numout_trans` | TRX IBK | 4.25 | 0.74 |
| `woe_cant_vehi` | `cantidad_veh` | SUNARP | 0.69 | **-0.14** |
| `woe_anti_negmeses` | `ant_negocio` | SUNAT | 141 | 90 |

Ese `-0.14` vehiculos es una de las tres imposibilidades que motivan el PASO 1.
La `woe_min_sldopasi06m` viene nula en 47.3% de IBK y 63.4% de SSFF.

Y en riesgo si observable (RCC/SENTINEL, comparable entre las tres): deuda telco
30 -> 57 -> 119, % de saldo en otras entidades 4.5 -> 8.7 -> 27.5, meses con atraso
>8 dias 0.14 -> 0.23 -> 0.35. **El SSFF tambien es mas riesgoso de verdad.** Separar
las dos cosas es justamente lo que se le pide a TreeSHAP.


### Las 39, medidas (query `sql_val/108_variables_por_poblacion`)

Peso = SHAP documentado en el informe del modelo. `mono` = la media va ordenada
IBK -> RESTO_TOP4 -> SSFF. Nulos solo se listan donde son distintos de cero.

| columna en la tabla | en el modelo | fuente | peso | IBK | RESTO_TOP4 | SSFF | mono | %nulo I/R/S |
|---|---|---|---:|---:|---:|---:|:-:|---|
| `woe_prm_decresldo12m` | `prom_dec_12m_total` | RCC | 9.1% | 28,937.77 | 17,587.76 | 4,471.94 | si |  |
| `woe_max_nrocredsldo06m` | `max_num_tip_cred_u6m` | RCC | 8.0% | 3.23 | 2.63 | 2.59 | si |  |
| `woe_nro_decresldo12m` | `cuenta_decre_12m_total` | RCC | 7.0% | 8.95 | 7.97 | 8.34 | **NO** |  |
| `rat_promsldnegdecre03y06m` | `ratio_prm_sald_neg_dct_3m_6m` | RCC | 6.8% | 0.55 | 0.30 | 0.59 | **NO** |  |
| `woe_cant_vehi` | `cantidad_veh` | SUNARP | 5.2% | 0.69 | 0.31 | -0.14 | si |  |
| `woe_cant_entireportsisnoreg` | `ctd_entreport12m` | SENTINEL | 4.8% | -0.61 | -0.43 | 0.15 | si |  |
| `woe_dpt_grupo_v2` | `dpt_grupo_v2` | RENIEC | 4.8% | 2.41 | 2.17 | 1.84 | si |  |
| `woe_edad` | `edad` | RENIEC | 4.7% | 15.72 | 20.49 | 40.76 | si |  |
| `woe_avg_porcsald_otrasent12m` | `avg_porcsald_otrasent12m` | RCC | 4.2% | 4.53 | 8.73 | 27.54 | si |  |
| `woe_prm_deudatelco12m` | `prm_ddatelc12m` | SENTINEL | 4.0% | 29.96 | 57.00 | 119.41 | si |  |
| `woe_anti_negmeses` | `ant_negocio` | SUNAT | 3.4% | 140.96 | 112.60 | 89.59 | si |  |
| `woe_prm_decresldopp12m` | `prom_dec_12m_pp_sf_total` | RCC | 3.1% | 399.08 | 412.33 | 436.21 | si |  |
| `woe_min_sldopasi06m` | `min_sldpdvtotal_6um` | PASIVOS-IBK | 2.8% | 6,345.11 | 3,860.32 | 455.97 | si | 47/62/63 |
| `woe_beta_nroenti` | `beta_entidades_dist_rd_u1a` | RCC | 2.7% | -0.01 | -0.01 | -0.00 | si | 3/8/1 |
| `woe_beta_sldoppcomer` | `beta_saldo_pc_u1a` | RCC | 2.3% | -875.70 | 49.89 | 265.48 | si | 87/78/40 |
| `woe_prm_decresldotc12m` | `prom_dec_12m_tc_total` | RCC | 2.2% | 525.83 | 337.18 | 165.46 | si |  |
| `woe_prm_porcsldoimpa12m` | `avg_pct_saldo_impago_u1a` | RCC | 2.0% | -0.91 | -0.79 | -0.81 | **NO** |  |
| `woe_prm_usotcfueraibk12m` | `prm_usotcrrstsf12m` | RCC | 1.9% | -1.19 | -0.98 | -0.26 | si |  |
| `woe_beta_sldotc12m` | `beta_saldo_tc_tot_u1a` | TRX-IBK | 1.9% | 65.71 | 6.26 | -25.72 | si | 79/83/85 |
| `woe_prm_nrotrxcashout06m` | `x6_numout_trans` | TRX-IBK | 1.8% | 4.25 | 2.46 | 0.74 | si |  |
| `woe_nro_dismsaldonormal12mcny` | `num_dsldnor_12um_cny` | RCC | 1.6% | -1.06 | -0.64 | 0.27 | si |  |
| `woe_peor_clasicony09m` | `peor_cls_sbs_9um_cny` | RCC | 1.5% | -1.47 | -1.21 | -0.42 | si |  |
| `woe_max_dismsldoretail03m` | `max_d_sldrctret_3um` | RCC | 1.5% | -784.51 | -616.49 | -391.34 | si |  |
| `woe_ciiu_grupo_v2` | `ciiu_grupo_v2` | TRX-IBK | 1.4% | 1.72 | 1.77 | 2.04 | si |  |
| `woe_max_dismsldo12rl` | `max_d_sld_12um_rl` | SUNAT | 1.3% | -19,989.67 | -24,610.91 | -546.00 | **NO** |  |
| `woe_nro_mesesdismsldoretail12m` | `num_meses_disldrctret_12m` | RCC | 1.1% | 0.77 | 0.77 | 1.54 | si |  |
| `rat_promsldnegdecreprin3y6m` | `ratio_prm_sald_neg_dct_prin_3m_6m` | RCC | 1.0% | 0.41 | -0.06 | -0.88 | si |  |
| `woe_nro_mesescastin06m` | `ct_in_6um` | RCC | 1.0% | 1.88 | 1.11 | 0.68 | si |  |
| `woe_prm_ratdispefect03m` | `prom_ratio_disp_ef_pnj_u3m` | RCC | 1.0% | 1.63 | 1.71 | 1.75 | si |  |
| `woe_max_nroentinegocny06m` | `max_num_ent_neg6um_cny` | RCC | 1.0% | -1.50 | -1.27 | -0.66 | si |  |
| `woe_max_dismsldonoprinc12m` | `max_d_sldretnoprin_12um` | RCC | 0.7% | -904.41 | -672.09 | -728.43 | **NO** |  |
| `woe_rat_sldo09msobre12mrl` | `rt9sld12_rl` | RCC | 0.7% | 0.09 | -0.18 | -0.96 | si |  |
| `woe_nro_mesesatrasmay8dias09m` | `num_meses_8dm_u9m` | TRX-IBK | 0.7% | 0.14 | 0.23 | 0.35 | si |  |
| `woe_beta_sldopp12m` | `beta_saldo_pp_u6m` | RCC | 0.7% | -571.39 | -359.15 | -278.39 | si | 92/90/79 |
| `woe_max_diasatras09mrl` | `max_dm9um_rl` | RCC | 0.6% | 8.65 | 9.80 | -0.33 | **NO** |  |
| `woe_prm_valorexpimp12m` | `x12_valor__impexp` | ADEX | 0.6% | 8,790.24 | 5,462.21 | 251.68 | si |  |
| `woe_nro_mesesdicmsldoprinc12m` | `num_meses_disldrctprin_6m` | ADEX | 0.4% | 2.87 | 1.26 | -0.37 | si |  |
| `woe_porc_messldogiro06m` | `pct_meses_sgiro_u6m` | RCC | 0.2% | 0.03 | 0.05 | -0.02 | **NO** |  |

## El mapeo de nombres

La tabla de score usa nombres de produccion (`woe_*`) y el artefacto usa otros.
El diccionario completo de las 39 esta en `shap_muestra.py`, constante `PROD2MOD`,
y fue verificado contra la tabla de variables del documento del modelo (variable x
descripcion x fuente x peso SHAP). **Si algo no calza, revisar ahi primero.**

Ojo: la columna `woe_rat_sldonormal3msobre12mrl` (`rt3sldnor12_rl` en el modelo)
falto en el analisis anterior. En el `95` ya esta, y son 39 completas.

---

## Requisitos

1. **El parquet** de `disc_model_owner.ds_adm_bpe_shap_muestra`, creado por
   `proyectos/bankbn/sql_prod/f4_export/95_shap_muestra.sql`.
   Son hasta 72,000 filas (3 poblaciones x 24 codmes x 1,000), sin `key_value` ni
   `tip_doc`. Si no esta descargado todavia, ver "Como generarlo" abajo.

2. **El artefacto: ya esta aca**, en `artefacto/model_ligthbm_admbank.sav`.
   Es el LightGBM de admision Bank BPE. Verificado antes de subirlo: carga como
   `Booster`, **4,000 arboles, 39 features**, `predict` y `pred_contrib` responden.

   ```
   sha256  b39855fa3406886ad107a13952d1343a6a66543ec71430c1a5f2b0ca0b183a19
   ```

   Si el sha no coincide, **para y reportalo** — no busques otro artefacto por tu
   cuenta: cual version del modelo se uso es justamente una de las incognitas.
   No hace falta ningun otro `.sav`. Los `model_ppnn_*` y `model_ppjj_*` son los
   modelos macro de la calibracion y no intervienen aca.

3. Python con `pandas`, `numpy`, `pyarrow`, `lightgbm`. **No instales el paquete
   `shap`**: LightGBM trae TreeSHAP adentro via `booster.predict(X, pred_contrib=True)`
   y es lo que el script usa. Version de referencia en la maquina de origen:
   pandas 3.0.3, pyarrow 24.0.0, lightgbm 4.6.0, numpy 2.x.

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
python shap_muestra.py <carpeta_o_ruta_del_parquet> artefacto/model_ligthbm_admbank.sav
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

## Que devolver — exactamente esto, en este orden

Se pide preciso porque el canal de vuelta es una persona copiando texto. **Cinco
bloques, nada mas y nada menos.** No resumas, no interpretes, no recortes filas:
pega los numeros crudos. La lectura se hace del otro lado.

**BLOQUE 1 — encabezado.** Cuatro lineas, completa los valores:

```
filas totales      = <n>
por poblacion      = IBK <n> / RESTO_TOP4 <n> / SSFF <n>
codmes min - max   = <aaaamm> - <aaaamm>
sha256 artefacto   = <salida de: certutil -hashfile artefacto\model_ligthbm_admbank.sav SHA256>
```

**BLOQUE 2 — la salida de consola del PASO 0 y el PASO 1, textual.** Son ~20 lineas.
Incluye la linea que empieza en `>>>`, que es el veredicto.

**BLOQUE 3 — la salida de consola del PASO 2, textual.** La tabla de 20 filas mas la
linea de `fuentes NO-RCC`.

**BLOQUE 4 — la salida de consola del PASO 3, textual.** La tabla de 15 filas.

**BLOQUE 5 — `outputs/shap_ibk_vs_ssff.csv` completo.** Son 39 filas + cabecera:
`variable, shap_ibk, shap_ssff, delta, fuente, pct_brecha`. Pegalo tal cual, las 39.

Si el script corta antes de llegar a alguno, **manda los bloques que si salieron mas
el traceback completo**. Un traceback sirve; un "fallo" no.

## Que NO devolver

- el parquet, ni ningun archivo de datos
- filas individuales, muestras de registros, cabeceras de `df.head()`
- `key_value`, `tip_doc`, o cualquier identificador (el parquet no los trae, pero
  tampoco los busques en otra tabla)

Si algo falla y hace falta mas para diagnosticar, **pedi un mensaje de error mas
explicito, no una muestra de filas.** La regla del repo es: el codigo entra, los
datos no salen.

## Lo que NO hay que hacer

- **No hagas `git push`.** Esta maquina solo lee del repo.
- **No cambies los coeficientes, ni la cadena de calibracion, ni el SQL.** Si algo
  parece mal, reportalo; no lo corrijas.
- **No busques otras tablas** para completar o validar. La poblacion es la que sale
  del `95` y nada mas. Ya se decidio asi: no existen tablas congeladas alternativas.
- **No sustituyas el artefacto** por otro que encuentres en la maquina.
- **No reinterpretes un PASO 1 que no reproduce como un bug a arreglar.** Es el
  resultado que se esta buscando. Reportalo con los numeros.

---

## Si algo no cuadra

Reportalo en vez de arreglarlo por tu cuenta. En particular:

- si el parquet trae menos de ~40,000 filas, o alguna poblacion falta
- si `n_estrato` viene nulo o en 1 para todo (romperia la reponderacion)
- si faltan columnas: el script las lista y corta solo
- si el paso 1 no reproduce: **eso es un hallazgo, no un error**. Reportalo tal cual
  con los numeros, es exactamente lo que se esta tratando de averiguar.
