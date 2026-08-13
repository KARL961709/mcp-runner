# TCNOBANK — cadena SQL de construcción del insumo de calibración

Construye **`disc_model_owner.ds_adm_vcnbank_tc_cal`**, insumo único de la calibración del
modelo **vcnbank** (CatBoost, 26 variables) sobre la PO de **admisión de tarjeta de crédito
no bancarizada**.

Un statement por archivo, sin `;`, UTF-8 ASCII sin BOM. El SQL no lleva racional: vive acá.

---

## Nombre y grano

| | |
|---|---|
| Tabla final | `ds_adm_vcnbank_tc_cal` — `adm` (admisión) · `vcnbank` (modelo) · `tc` (producto) |
| Grano | **cliente × entidad × mes de alta** |
| Ventana de alta | **201902 – 202605** (88 meses) |
| Snapshot del RCC | **202606**, pinneado |

La ventana **no es un `WHERE`**: la tabla lleva todos los meses y `flg_calib` hace el recorte.
Cada horizonte tiene su propia madurez, así que los cortos usan más meses que los largos.

---

## Orden de ejecución

`sql_prod/` se corre **de a uno** con `-Only`. `sql_val_cal/` corre en lote.

```
00_reset/     16 DROP, solo para reconstruir desde cero
01_staging/   05 (x10 tramos) · 10 · 11 · 20 · 21 · 30 · 40 · 50
02_gate/      60 · 65 · 70 · 81 · 90..93
sql_val_cal/  00 · 90..99
```

| paso | produce | qué hace |
|---|---|---|
| `05_rcc_agg_tNN` | `_05_rcc_agg` | colapsa el RCC a cliente × entidad × mes |
| `10_po` | `_10_po` | alta de TC derivada del RCC |
| `11_po_key` | `_11_po_key` | `sbs_value` y `cod_cuc` + cobertura |
| `20_rcc_base` | `_20_rcc_base` | origen, en variantes m0 y m2 |
| `21_rcc_flags` | `_21_rcc_flags` | históricos u6m / u12m / u24m |
| `30_drivers` | `_30_drivers` | tipo de ingreso y arquetipo salud |
| `40_pdraw` | `_40_pdraw` | `pd_raw` del CatBoost |
| `50_targets` | `_50_targets` | `target_01m` … `target_12m` |
| `60_filtros` | `_60_filtros` | 18 filtros, una columna cada uno |
| `65_dedup` | `_65_dedup` | prelación con orden total |
| `70_cal` | **`_cal`** | ensambla y deriva `flg_clean` / `flg_calib` |
| `81_macro_serie` | `_81_macro` | serie mensual + 7 variables macro |
| `90..93` | `_px_*` | master · clean · dirty · macro |

---

## Por qué la capa `05_rcc_agg` existe

El RCC son **114 particiones de ~60M filas**. Sin colapsarlo una vez, cada paso posterior
volvería a escanearlo. Se construye en **10 tramos generados por script**, y ninguno cruza la
frontera `201812 / 201901` para que la fuente salga del mapa y no de una asignación a mano:

```
d_perm_aws.t_fact_report_rcc_rsk  ->  [201701, 201812]
e_perm_aws.t_fact_report_rcc_rsk  ->  [201901, 202606]
```

Medido (q62): en el solape las dos copias coinciden **al decimal** en filas, clientes,
entidades, líneas TC y saldo. `d_perm` no es otra versión — es la misma con más cola.

---

## Por qué la población se deriva del RCC

Medido (q82), contra `tng_altas` en 202404:

| entidad | recall |
|---|---|
| Falabella · Scotiabank · BBVA · Fin. UNO · Ripley · BCP | **99.83 – 99.99 %** |
| **Interbank** | **74.38 %** |

Fuera de IBK la derivación reproduce las altas oficiales casi perfecto. IBK cae porque
`tng_altas_ibk` sale del sistema de originación interno y no del RCC.

**Se deriva todo del RCC** igual: para SSFF no existe otra fuente de alta, y mezclar
definiciones dejaría a IBK con una población construida distinto que a las otras once,
cuando el modelo las puntúa igual. **Desviación firmada**, con la causa identificada.

---

## Target — `target_01m` … `target_12m`

```
target_Nm = 1     malo en ALGÚN mes de [T0+1, T0+N]
          = 0     no lo es y la ventana está madura
          = NULL  T0+N > 202606  (inmaduro)
```

**MALO** = `max dm_tc > 60` **OR** evento duro (castigo / judicial / refinanciado /
reestructurado). Dos universos: la mora vive en las cuentas de tarjeta (**entidad**), el evento
duro en cuentas más amplias (**cliente**), igual que producción.

Familia **monótona no decreciente**: una vez malo en el mes k, malo para todo N ≥ k.

**El evento se evalúa antes que la zona gris.** Producción lo hace al revés y por eso pierde
**2,576 defaults** (q15, q26): un registro con castigo futuro pero mora indeterminada sale
etiquetado INDETERMINADO y cae fuera del numerador *y* del denominador. La PO del KAT ya usa el
orden correcto — esto alinea con ella, no inventa criterio.

---

## Los 18 filtros — una columna cada uno

Ninguno se funde en cascada. El `n` de una cascada mide el **residual**, no el filtro: medido dio
entre **6 y 25 veces menos** que el aislado (q91 contra q05).

| CASO | destino | filtros |
|---|---|---|
| **3** | `flg_clean = 99` | `f_banc_u12m` · `f_entidades` |
| **2** | `flg_clean = 0` | `f_edad_rango` · los 5 de origen · `f_cast_u24m` · `f_jud_u24m` · `f_ref_u6m` · `f_mayor_cpp` · `f_gar_conv` · `f_fraude` · `f_swap_u12m` |
| **1** | liberado | `f_swap_p12m` · `f_repro_p12m` |
| disponibilidad | `flg_calib` | `f_edad_nomatch` |

`f_edad_rango` y `f_edad_nomatch` van **separados**. Producción los funde: `NULL BETWEEN 21 AND 75`
cae al `ELSE 0` y ambos salen como EDAD. Medido (q96): el corte real es **cerca de mitad y mitad**.

Todos con `COALESCE`: ningún filtro puede quedar NULL — un NULL fuerza dirty en silencio.

### Anclajes

| filtro | ancla |
|---|---|
| los 5 de origen | **m−2** (el RCC de T0 no existe en T0). La variante m0 queda en `ctrl_*_ori_m0` |
| `f_fraude` | `p_codmes <= m−2`. La q93 probó que la tabla es **delta sin reversiones** |
| `f_gar_conv` | m−2 |
| `f_edad_rango` | k=0 — `fec_nacimiento` es inmutable |

---

## Los tres `flg_clean`

```
flg_clean          99 = banc_u12m o entidades · 1 = pasa los 13 CASO2 · 0 = resto
flg_clean_sin_ent  trata entidades como dirty
flg_clean_macro    suelta fraude y swaps
```

`f_entidades` quedó en 99 **sin firmar**: la q91 midió que excluye población **más riesgosa**
(bad-rate 13.10 % contra 10.37 % de la base). Por eso sale también la variante que lo trata como
dirty — si la decisión cambia, no hay que reconstruir.

`flg_clean_macro` es para la serie larga: fraude solo existe desde **202106** y los swaps desde
**202201**. Soltarlos gana esos meses para estimar ρ y el modelo macro. La brecha está acotada:
fraude vale a lo sumo **0.11 pp** de LRA.

```
flg_calib = 1  si  flg_clean <> 99  y  pd_raw no nulo  y  sin falla de RENIEC ni de madurez
```

---

## Drivers

**`tipo_ingreso`** — cascada de ingresos, con la lista de exclusión de **cuatro** fuentes
(`INFERIDO`, `EXPERIAN`, `SUSALUD`, `INFERIDO_IND_MVP`), no la de dos del Recibido.
`ctrl_fuente_nueva` marca el régimen 202604+; como la ventana termina en 202605, dentro de la
serie casi no dispara.

⚠️ El segmento **se recompuso en el tiempo**: BHI era el 72.7 % en 2022 y desapareció en 2023;
EXPERIAN lo reemplazó y cae a MIXTO. Un mismo cliente cambia de segmento sin cambiar de empleo.
**No usarlo como eje de calibración sobre la serie larga sin redefinirlo por inclusión.**

**`t_inca_sa`** — arquetipo salud, con rezago **−2** como pide `tablas.txt`. Llave `party_id`, vía
`t_mst_inter_ibk_base_cliente`. Se emite crudo, sin transformar.

⚠️ La q27 midió conteos **idénticos** en meses consecutivos (202305–202310 y 202311–202404), lo
que sugiere foto repetida. Si el contenido no cambia, el rezago −2 no protege de nada y el eje es
segmento estático, no driver PIT. `ctrl_inca_sin_dato` marca la ausencia — solo cubre 202305+.

---

## Prelación

Se emiten **las dos** porque la decisión no está tomada:

- `prelacion_cod` — replica producción (`entidad ASC`), que da prioridad sistemática a BCP por su
  numeración SBS
- `prelacion_sld` — ordena por saldo de tarjeta, el criterio económico

**Ninguna mira el target.** Las de producción a 6, 9 y 12 meses ordenan por
`flg_cc_default_desc`: eso es look-ahead en la selección de la fila, y las RD reportadas antes
salieron con ese sesgo.

---

## La calibración vigente se descarta

Está en `s3/models/calibobjects/` y corre en producción: dos árboles de 3 hojas sobre inflación y
desempleo que aplican un **shift aditivo en logit**, segmentados por situación laboral, estimados
**excluyendo BCP** (`sinbcp`) y con `min_samples_leaf = 6`.

No tiene ancla de nivel ni pendiente. La q24 midió que la brecha real pide **pendiente 1.15** en
espacio probit (R² 0.9925) — un shift puro no puede darla. Se trae como `pd_cal_vigente` solo para
contraste.

---

## QA

| script | qué gatea |
|---|---|
| `00_cobertura_pasos` | filas y meses de cada paso materializado |
| `90_qa_reconcilia` | `99 + 1 + 0 = universo` · dominio · duplicados · prelación |
| `91_qa_targets` | rango · madurez · **monotonía (11 pares)** · cross-check mora y evento |
| `92_qa_targets_global` | sin maduros · degenerado, por horizonte |
| `93_qa_filtros_dominio` | ningún filtro NULL |
| `94_qa_funnel` | `n` aislado y **bad-rate** por filtro |
| `95_qa_serie_mensual` | población y tasas por mes |
| `96_qa_lookahead` | ningún filtro dispara antes de que su fuente exista |
| `97_qa_drivers` | cobertura de drivers y llaves por año |
| `98_qa_delta_reanclaje` | m0 contra m2 en los 5 de origen |
| `99_qa_agg_cobertura` | capa agregada sin hueco ni solape |

Toda salida reporta **magnitud** además del veredicto.

---

## Pendientes de firma

1. **`f_entidades`** — 99 o dirty. Excluye 1.75M registros con bad-rate 13.10 %
2. **Reanclaje m0 → m2** — el delta lo mide `98_qa_delta_reanclaje`
3. **Prelación** — `cod` o `sld`
4. **`t_inca_sa`** — driver o segmento estático, según si el contenido varía
5. **`tipo_ingreso`** — redefinir por inclusión antes de usarlo como eje

## Conflicto de documentación

`ESTILO_SQL.md §1` pide terminar cada sentencia con `;`. El `CLAUDE.md` del mcp-runner lo prohíbe
("ni siquiera en comentarios") y el gate **G0** lo rechaza. **Manda el runner** — conviene
actualizar el `.md`.

---
## Correcciones tras la QA del 2026-08-12

**H. f_malo_ori pasa a m0.** Medido: la variante m2 daba 0 exacto sobre 13.5M filas. La causa es
estructural, no un bug de SQL: `malo_ori` sale de `05_rcc_agg` filtrado a `entidad = p.entidad`, y
la poblacion es un ALTA, asi que en m-2 no existe fila de esa entidad. Los otros cuatro origenes
(`cast/jud/ref/ree`) salen del CTE `cli`, agregado a nivel CLIENTE sobre todas las entidades, y por
eso si tienen fila en m-2. Es el unico origen que no se puede reanclar.

Contrafactual (d4, sobre `cal` con la prelacion vieja):

    dispara malo_ori_m0    n = 199,706   1.47% del universo   bad-rate 75.12%   dm_fut medio 135 d
    no dispara             n = 13,388,044                     bad-rate 13.59%   dm_fut medio  15 d
    de los que disparan, 60,199 estaban entrando como flg_clean = 1 con bad-rate 66.62%

    delta_lra_pp sobre la base clean = -1.57 pp  (13.82% -> 12.25%)

Decision: DIRTY (flg_clean = 0), anclado en m0, no liberado. Un bad-rate 5.5x no es ruido. No va a
99 porque no es un filtro de alcance: el 99 sigue reservado a `f_banc_u12m` y `f_entidades`.
`ctrl_malo_ori_m2` viaja como control para poder medir el contrafactual desde la tabla.

**I. Fan-out en 60_filtros.** `fac` se unia por RANGO de meses (`su` 12 meses atras, `sp` 12
adelante) sin agregar: un cliente con 12 meses de facilidades generaba 12 filas. Medido con d1:

    11_po_key, 20_rcc_base, 21_rcc_flags, 50_targets, 30_drivers, 40_pdraw   0 duplicados
    60_filtros   16,731 llaves duplicadas   19,878 filas extra
    cal          16,731 llaves duplicadas   67,660 filas extra   <- 70_cal une f con d por las
                 4 llaves, asi que un grupo duplicado n veces sale n al cuadrado

Arreglo: CTE `sw` que agrega al grano (codmes_mrm, cod_cuc) ANTES de unir, con las tres ventanas
resueltas por CASE dentro del mismo max(). Un solo LEFT JOIN por dos llaves.

**J. flg_hist se separa de flg_calib.** El score `scr_vcnbank_rsk` arranca en 202303, y `flg_calib`
exigia `pd_raw IS NOT NULL`, asi que la serie de RD para el modelo macro quedaba vacia en
201902-202302 pese a tener target completo. Son dos preguntas distintas:

    flg_hist   alcance + datos, SIN score y SIN madurez  -> serie de RD, ~201902-202506
    flg_calib  flg_hist + pd_raw + madurez 12m           -> base de calibracion, 202303-202506

La madurez por horizonte la gobierna el NULL de cada `target_0Nm`: los horizontes cortos compran
ventana sin necesitar flag propio. `81_macro_serie` y `93_export_macro` pasan a `flg_hist`;
`pd_raw_clean` se queda en `flg_calib` porque si necesita el score.

---
## K. La poblacion tenia no-originaciones y la regla que las saca

`tng_altas` es el reporte de ORIGINACIONES de cada entidad; el RCC es un reporte de SALDOS.
Derivar el alta como "primera aparicion en 13 meses" confunde originar con adquirir o
reanudar reporte. Medido en la ventana [202201,202506] sobre las 5 entidades de alcance:

    entidad  origen      n         rd_12m   pct_malo_ori
    00001    en ambas    909,588    7.12 %     0.07 %
    00001    solo rcc     64,555   67.07 %    77.31 %
    00006    solo rcc      4,001   65.91 %     9.32 %
    00004    solo rcc        518   27.41 %    33.40 %
    00142    solo rcc         83   12.05 %     2.41 %
    00002    solo tng    269,115      -          -        <- el RCC no ve 25 % de IBK

Lo que las delata NO es el estado contable (98.4 % aparece vigente), NI la ventana del alta
(tc_13_24m da 41.70 contra 40.58: no separa), sino el SALDO. Un alta real de BCP llega con
10,004 entre saldo y linea; una no-originacion llega con 32. Son cuentas muriendo: resto en
14-x, linea 81-923 ya cancelada.

    BCP    en_tng=1   con linea 909,397   sin linea    191
           en_tng=0   con linea     757   sin linea 63,798
           precision 99.70 %   recall 98.83 %
    BBVA   precision 97.6 %    recall 95.5 %

`f_sin_linea = 1` cuando `sld_linea = 0`, y va a **99**: no es sucio, es otra poblacion. Se
suma a los dos de alcance que ya existian y entra en `flg_hist = 0`.

Con la regla, el RCC limpio reproduce `tng` (BCP recall 99.6 %, precision 99.9 %), asi que NO
hace falta cambiar de fuente ni partir el uso entre calibracion y macro. Cambiar de fuente en
202201 metia un escalon de ~1 pp en la serie de RD que el modelo macro leeria como ciclo.

**Por que importa mas para macro que para calibrar.** En la ventana de calibracion la
contaminacion son 2,850 registros, +0.26 pp. Pero decae en el tiempo (0.82 % en 202303 a
0.15 % en 202506), asi que inyecta una TENDENCIA falsa en la serie con la que se elige la
variable macro. Eso no lo absorbe un intercepto.

**Riesgo asumido, con gate.** La regla se midio en BCP y BBVA. Si alguna entidad no reportara
81-923 le borraria toda la poblacion. `86_qa_regla_linea` falla si alguna entidad supera 25 %
sin linea en algun anio.

## L. f_malo_ori cambio de motivo, no de decision

Se aplica porque limpia poblacion, no porque saque malos: 98.8 % de los malo_ori de BCP son
altas que tng no reconoce. Sigue en dirty anclado en m0. Su recall como detector es 77.3 %
contra 98.8 % de la regla de linea, asi que ahora es redundante en su mayor parte.

## M. sld_usado y sld_linea entran como columnas

`05_rcc_agg.saldo_tc` sumaba 14-x de TC junto con 81-923 en el mismo campo, asi que
`prelacion_sld` ordenaba mezclando deuda con linea disponible. `12_saldo_perfil` lee el RCC
crudo solo para las llaves de la po (solo rama e_perm: la po arranca en 201902) y saca la
linea; el usado sale por resta. `prelacion_sld` pasa a ordenar por `sld_usado`.

Ademas es la segmentacion mas fuerte del dato, y no estaba en ninguna columna:

    entidad   solo linea no utilizada        con saldo usado
    00001     54.3 %   rd  2.17 %            45.7 %   rd  8.10 %
    00002     21.6 %   rd  6.69 %            78.4 %   rd 11.29 %
    00006     54.1 %   rd  4.68 %            45.9 %   rd 15.64 %
    00142     36.6 %   rd  7.07 %            63.4 %   rd 19.84 %

Viaja como `ctrl_solo_linea`. El efecto entidad que ve el modelo hoy es en parte esta mezcla.

## Limitaciones que no son corregibles midiendo

1. **IBK pierde 25 % de sus altas en el RCC.** No se puede medir su rd porque no estan en la
   tabla. IBK es 16 % de la base, asi que el sesgo podria llegar a ~1 pp.
2. **De 201902 a 202112 no hay arbitro.** `tng_altas` arranca en 202201. La regla de linea se
   calibra en el solape y se asume valida hacia atras. Eso es firma, no medicion.

---
## N. El digito 3 de la subcuenta 14 no existe: f_ree_ori esta muerto

Medido sobre 202412, cuenta 14, tipo_credito 11 y 12. La estructura es
`14` + moneda + estado + `03`:

    141103  10,385,201  47.9 %   normal 91.8 %                 soles,   vigente
    142103     849,006   3.9 %   normal 94.2 %                 dolares, vigente
    141403     154,808   0.7 %   dudoso y perdida 53.9 %       refinanciado
    141503     658,252   3.0 %   mora mayor a 60  76.9 %       vencido
    141603      36,540   0.2 %   perdida 99.7 %                judicial
    141803   7,118,421  32.8 %   mora 0 %                      devengados
    141903   1,845,441   8.5 %   dudoso y perdida 43.8 %

**No hay 1413xx.** `05_rcc_agg.sld_ree` lee `substr(cod_cuenta_rcc,4,1) = '3'`, un digito que
no aparece nunca, y por eso `f_ree_ori` dispara **1 vez en 13,520,090 filas**. `sld_ref` lee
el digito 4 y captura refinanciados y reestructurados juntos.

**No es desviacion propia: viene de la PO de produccion.** En `88_qa` la etiqueta
`REFINANCIADOS EN EL ORIGEN` aparece con 120 casos y `REESTRUCTURADOS EN EL ORIGEN` no
aparece nunca, asi que el filtro tampoco corre en produccion. Se replica tal cual y se
documenta. Cambiarlo seria una desviacion R11 que hay que firmar aparte.

## O. Decision sobre BCP 2020 y 2021

`86_qa_regla_linea` fallo en BCP 2020 con 48.7 % sin linea contra 1.0 % en 2019. Medido:

    anio  sin_linea      n       pct_d4    sld_usado_medio    rd_12m
    2019      1        2,916     0.240 %        7,235         30.25 %
    2020      1      147,634     0.091 %          689         68.84 %
    2021      1       57,523     0.217 %        1,380         60.46 %
    2022      1       42,216     1.206 %        1,988         71.37 %

**No son reestructuraciones**: `d4` es 0.09 a 1.2 %. La hipotesis COVID queda refutada.

Pero el perfil de 2020 y 2021 es identico al de 2022 —saldo chico, sin linea, rd 60 a 71 %—
y 2022 SI esta en la ventana de `tng`, donde el 98.8 % de ellos resulta no-originacion. Lo
que cambia entre anios es el VOLUMEN, no la naturaleza.

**Decision: la regla se aplica en los 88 meses.** No porque este identificado el mecanismo
—no lo esta— sino porque la firma coincide con la poblacion que `tng` confirma. El anio
atipico es 2019, no 2020, y son 2,916 registros: inmaterial en cualquier direccion.

`86_qa` se conserva como esta, fallando en BCP 2020. Un gate que falla y esta firmado con
evidencia es informacion; subirle el umbral para que pase seria esconderlo.

---
## P. Validacion contra la logica de nodos (Recibidos2), hecha en local

El master exportado trae `id_hash = to_hex(md5(tip_doc || '|' || id_value || '|' || entidad))`,
que es reproducible desde `nodos.csv` (ojo: su `cod_instit_financiera` viene sin ceros a la
izquierda y hay que rellenar a 5). Eso permitio cruzar por llave SIN usar el puente.

**Poblacion.** 16,651 de 18,664 filas del csv estan en el master (89.21 %). Por volumen el csv
es el 92.7 % de nuestro `calib_clean` de IBK, con la misma forma mes a mes (89.9 a 95.4 %).
No es una muestra: es la misma poblacion menos ~7 %.

**Score: es el mismo.** Sobre los registros cruzados:

    PROB_VC_NB_NEW_V3   media 8.9515 %   p50 6.8900 %
    nuestro pd_raw      media 9.0931 %   p50 7.0613 %
    correlacion 0.9973   |dif| media 0.36 pp   identicos 0 %

La alarma de 8.82 contra 13.4 comparaba su poblacion IBK con cascada completa contra nuestra
base clean de cinco entidades. Sobre los MISMOS registros la brecha es 0.14 pp. Hay diferencia
de version (ningun valor coincide al sexto decimal) pero la dispersion supera al sesgo medio:
es ruido, no otro modelo. Queda cerrado que `e_perm_aws.scr_vcnbank_rsk.prob_model` es el
score correcto.

**Target: 100 % exacto.**

                        nuestro target_12m
    csv TIPO_CLIENTE         0        1
    BUENO               12,929        0
    MALO                     0      987
    INDETERMINADO        1,222       31
    INSUFICIENTE         1,450       32

Cero discrepancias sobre BUENO/MALO (n=13,916). Los 63 de INDETERMINADO e INSUFICIENTE son los
estados liberados, que en la vigente no llevan etiqueta y en la nuestra si.

**Desviacion entidad contra cliente, medida.** `TARGET60_12_VC` es el target de Vision Cliente,
a nivel CLIENTE. Sobre los mismos 13,916 registros:

    por entidad  (TIPO_CLIENTE)     7.093 %
    por cliente  (TARGET60_12_VC)   7.804 %      +0.71 pp

De los que difieren, el 62 % tiene `max_dm_fut = 0` en IBK y NINGUNO supera 60 dias ni tiene
evento duro: cayeron en otra entidad. Confirma que el sesgo es unidireccional, solo quita
malos, y ahora esta cuantificado en 0.71 pp.

**Los nodos.** RD 4.18 / 6.04 / 9.80 con reparto 23.2 / 27.0 / 49.8. OJO: la bad-rate del csv
cae de 10.77 % en 202410 a 5.99 % en 202504, que es frontera de madurez y no comportamiento,
asi que las RD de los nodos estan subestimadas en los meses recientes.

`d21` y `d26` se retiran del lote: ambos quedaron respondidos en local contra el parquet.

---
## Q. Ancla del AFP: medida, corregida en codigo, no reconstruida

El script de nodos ancla la exclusion AFP en `a.codmes >= k.codmes`, o sea el retiro
hasta el mes M inclusive. En campania un retiro hecho a mitad de M no se conoce, asi que
la ancla implementable es M-1. El original nunca se penso para campania.

Medido ANTES de decidir si valia una reconstruccion (v21):

    IBK  N1  el flag se da vuelta    40 registros   1 malo   rd  2.50 %
    IBK  N2                          25             0        rd  0.00 %
    IBK  N3                          50             0        rd  0.00 %
    resto                            48             0        rd  0.00 %

115 registros de IBK sobre 103,656 = 0.111 %, con UN malo entre los tres nodos. Migran
como maximo 75 hacia N1, y las LRA quedan:

              hoy          corregido        delta
    N1     5.3133 %        5.2921 %       -0.021 pp
    N2     8.3861 %        8.3931 %       +0.007 pp
    N3    13.9606 %       13.9733 %       +0.013 pp

Contra un error de estimacion de +-0.33 pp en la LRA de N1. El cambio esta un orden de
magnitud debajo del ruido. **Se corrige el codigo y NO se reconstruye**: la tabla
exportada usa M y la diferencia esta cuantificada arriba.

**Nota de proceso.** R5 pide medir el rezago POR FUENTE. Los anclajes de PLIN, pasivos
y cuenta sueldo se copiaron del script original en vez de medirse. Que las tres tengan
M-1 disponible se confirmo despues, con mediciones hechas por otro motivo (d23, v3, v6):

    t_agg_retail_user_trx_plin   ultimo mes 202608   rezago 0
    t_aws_360_cliente_mes_d3     ultimo mes 202607   rezago 1
    t_rsk_cta_sueldo             ultimo mes 202607   rezago 1

O sea que el nodo ES computable en campania, pero eso salio por suerte y no por
verificacion deliberada. Si alguna hubiera tenido dos meses de rezago, el nodo habria
quedado no implementable sin que nada lo detectara.
