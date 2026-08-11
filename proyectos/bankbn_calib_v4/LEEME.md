# calib_v4 — re-ajuste de la calibracion Origen Bank BPE

Proyecto autocontenido para decidir **sobre que poblacion se ajusta la calibracion**.
Sucede a `PROPUESTA_FINAL_V2.md` y ataca sus decisiones 1, 2 y 4, que seguian abiertas.

---

## Nomenclatura, para no confundirse

**El top 4 son BCP (00001), IBK (00002), SCOTIA (00004) y BBVA (00006). IBK esta adentro.**
La etiqueta `RESTO_TOP4` que usan las queries es **el top 4 sin IBK**. Cuando aca se dice
"TOP 4 completo" es la union de `IBK` + `RESTO_TOP4`, que son los cuatro. Nunca se suma IBK dos veces.

| etiqueta en las queries | quienes son | % del libro |
|---|---|---:|
| `IBK` | Interbank | 1.3% |
| `RESTO_TOP4` | BCP, BBVA, Scotiabank | 11.4% |
| `SSFF` | todo lo demas: cajas, financieras, edpymes | 87.2% |

---

## Por que existe

Medido sobre la poblacion completa (query `bankbn/sql_val/113`), la calibracion vigente
**sobre-predice en las tres poblaciones, y muy desparejo**:

| poblacion | % del libro | PD asignada | mora observada 12m | ratio |
|---|---:|---:|---:|---:|
| IBK | 1.3% | 5.27% | 3.55% | 1.48 |
| RESTO TOP 4 | 11.4% | 7.71% | 4.94% | 1.56 |
| **SSFF** | **87.2%** | **10.61%** | **5.37%** | **1.98** |

La causa no es segmentacion sino **extrapolacion**: el ajuste se hizo sobre IBK, donde
el 94.5% de la muestra vive debajo de `pd_raw` 13%. Arriba de 13% la curva se apoya en
**190 registros con 14 defaults**, y ahi vive el 35.5% del SSFF.

Dato operativo que lo hace barato de arreglar: **`flg_calib = 1` ya es exactamente
el TOP 4 completo** (BCP, IBK, SCOTIA, BBVA) — el SSFF tiene `flg_calib = 0` en el 100% de los casos. El cambio es
quitar el filtro `IBK` que se aplica encima, no construir un flag nuevo.

---

## Orden de ejecucion

**1 · Dimensionar antes de construir** (read-only, barato)

```
.\Go.ps1 -SqlDir proyectos/bankbn_calib_v4/sql_val -Only 00_dimension_insumo
```

Devuelve filas por poblacion x bloque x evaluable x flag de Impulsa. Sirve para saber
cuanto pesa el parquet **antes** de generarlo.

**2 · Construir y bajar el insumo**

```
.\Go.ps1 -SqlDir proyectos/bankbn_calib_v4/sql_prod -Only 10_reset_insumo
.\Go.ps1 -SqlDir proyectos/bankbn_calib_v4/sql_prod -Only 11_insumo_calibracion -S3Datos "s3://<bucket>/<prefijo>/calib" -Bajar
```

`0 filas` en ambos es **correcto**: `Run-Athena.ps1:177` fuerza `$lineas = 0` para
`CREATE`/`DROP`, porque un CTAS no devuelve result set. No es sintoma de nada.

`-S3Datos` tiene que apuntar a un prefijo **nuevo y vacio**: el `-Bajar` sincroniza el
prefijo entero. La tabla es externa, asi que el `DROP` no limpia S3 — por eso el
`external_location` va versionado. **Va en `calib_v4b/`** desde que se agregaron
`target_01m/02m/03m`: cada cambio de esquema del insumo obliga a un prefijo nuevo, o el
`CREATE` responde `HIVE_PATH_ALREADY_EXISTS`. El prefijo viejo `calib_v4/` se puede borrar
a mano cuando convenga.

El parquet cae en `$LocalDatos\calib_v4b\`.

**3 · Verificar el insumo**

```
.\Go.ps1 -SqlDir proyectos/bankbn_calib_v4/sql_val -Only 12_qa_insumo
```

Nueve chequeos. Los dos que importan: **F** debe dar 0 (ningun SSFF con `flg_calib=1`)
y **H** debe dar tantos pares distintos como trimestres (confirma que `fhat` es
trimestral y no vino corrupto).

**4 · Ajustar**

```
python fit/calibrar.py <carpeta_del_parquet>
```

---

## Que hace `calibrar.py`

**PASO 0 es una compuerta.** Reimplementa la cadena vigente —beta-cal PNN / logit-cal
PJJ, `rho_i` de Basilea por cuenta, Vasicek con `f_t` capeado, re-ancla— y la compara
contra `pd_cal`, `rho_i` y `prob_modelo_cal` de la tabla. **Si no reproduce a 1e-9, para.**
Sin esa compuerta estariamos comparando una reimplementacion distinta contra si misma.

*(Verificado sobre la muestra del 2026-08-11: reproduce a 1e-16, y la puntuacion al entero.)*

**PASO 0B mide el ciclo, y esto se agrego despues de dimensionar.** El `00_dimension_insumo`
mostro algo que reordena el diagnostico: la ventana de ajuste (202206-202506) tiene una
mora muy superior a la de las cosechas recientes.

| | RD en la ventana de ajuste | RD en 202407-202506 |
|---|---:|---:|
| IBK clean | **8.84%** | 3.55% |
| RESTO TOP 4 clean | **8.62%** | 4.94% |

Eso es correcto por diseno: el LRA de PNN vale 0.0978 y coincide con ese 8.84%. Es una
calibracion through-the-cycle. **Quien tiene que cerrar la brecha es el ajuste PIT**, o sea
`f_t` con `lambda = 0.35`. Y hay razones para dudar de que alcance: el rango completo que
el cap permite mueve la PD de 10.01% a 6.75% — **3.26 pp de amplitud** — contra una brecha
de 5.3 pp entre la ventana de ajuste y la cosecha actual.

El PASO 0B lo mide sobre el dato: correlacion de `f_t` contra la mora realizada por
trimestre, y el `lambda` que igualaria la amplitud observada. **Necesita al menos 8
trimestres**; con menos, avisa y no opina.

**PASOS 1 y 2** ajustan ocho variantes con la misma cadena y backtestean las tres poblaciones:

| | poblacion de ajuste | lambda |
|---|---|---|
| A | **solo IBK**, ex-Impulsa — reproduce el diseno vigente | 0.35 |
| B | **TOP 4 completo** (BCP+IBK+SCOTIA+BBVA), ex-Impulsa — **la propuesta** | 0.35 |
| C | TOP 4 completo con Impulsa — mide cuanto pesa excluirla | 0.35 |
| D | todo el libro, SSFF incluido | 0.35 |
| E | TOP 4 completo mas una isotonica encima — precedente: el bloque dirty de REMEDIACION la usaba | 0.35 |
| F | solo IBK con lambda mayor — aisla ciclo de poblacion | 0.55 |
| G | TOP 4 completo con lambda mayor | 0.55 |
| H | TOP 4 completo con lambda alto | 0.75 |

**A contra F** es la comparacion que separa las dos causas: misma poblacion, distinto
lambda. Si F corrige buena parte del sesgo, el problema era el ciclo. Si no, era la poblacion.

**PASO 3** es out-of-time: ajusta con el 70% viejo de los trimestres y evalua en el 30%
nuevo. Una variante que solo se ve bien in-sample no sirve.

---

## Criterio de decision

**No hay adopcion automatica.** El script imprime y la decision es humana. Estos son los
gates, en orden de prioridad:

1. **`SSFF >= 10%` no puede quedar debajo de 1.00.** Es el tramo donde opera el corte de
   campanas. Si la PD queda debajo de la mora observada, se aprueban leads mal
   precificados: cambiamos un problema comercial por uno de riesgo. **Este gate manda
   sobre todos los demas.**
2. **Ninguna poblacion arriba de ~1.30.** Es el reclamo original de campanas.
3. **IBK no puede empeorar.** Es el libro propio y alimenta provisiones.
4. **El out-of-time tiene que sostener 1 y 2.**
5. **Los coeficientes tienen que ser estables.** Si `b1` del nivel se mueve mucho entre
   variantes, no se firma: se declara fragil y se busca otra forma.

### Lo que ya sabemos del ensayo sobre la muestra (2026-08-11)

Corrido sobre 24 meses y muestra estratificada, no sobre esto:

- **El nivel mejora fuerte y de forma estable**: IBK 1.48 -> 1.06, TOP4 1.56 -> 1.02,
  SSFF 1.98 -> 1.15. Se sostuvo en las cuatro variantes probadas.
- **Pero el gate 1 se rompe**: el SSFF arriba de 10% de PD cae a **0.73–0.88** segun la
  variante. Es exactamente la zona del corte.
- **Y el nivel PNN es fragil**: `b1` va de 0.245 a 0.973 segun ponderacion y ventana.
  Las re-anclas, en cambio, son solidas: 1.32–1.34 en todas.

Por eso este proyecto corre sobre la **ventana completa** y con la **poblacion completa**:
el ensayo uso 202407–202506, la mitad, y con la era Impulsa adentro.

Si el gate 1 se vuelve a romper con el dato completo, la salida **no** es adoptar igual:
es la variante E (isotonica) o un piso por banda, y volver a medir.

---

## Lo que este proyecto NO toca

`rho`, `lambda`, la variable macro `f_t` y sus bounds, y la forma de la cadena. Todo eso
queda como esta. Aca se decide **una sola cosa**: sobre que poblacion se estima el nivel
y la re-ancla.

El MoC tampoco se toca. Hoy vale 0 y esa decision sigue abierta en la propuesta.
