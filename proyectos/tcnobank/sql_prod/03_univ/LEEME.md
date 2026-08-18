# 03_univ - la calibracion sobre la poblacion objetivo

Tabla `disc_model_owner.scr_univ_vcnbank_tc_cal`. Una fila por cada fila de
`scr_vcnbank_rsk` en **202401 a 202608** (32 meses, ~825M filas), con
`prob_modelo_cal` y `puntuacion_cal` = **nuestra** calibracion.
Las que la fuente traia con esos nombres viajan como `*_vigente`.

## Que es esta tabla

Es la **poblacion objetivo sobre la que se lanza el modelo**, no altas: los
desembolsos todavia no ocurrieron. Por eso no trae mora ni identificacion de
alta, y no tiene por que traerlas — un modelo de admision existe para
pronunciarse antes.

La calibracion vigente ya vive en esta superficie. Este build la reemplaza, y
como las dos viajan lado a lado sobre las mismas filas se comparan de frente:

| nuestra | vigente |
|---|---|
| `prob_modelo_cal` | `pd_cal_vigente` |
| `puntuacion_cal` | `puntuacion_cal_vigente` |

## Como engrana la inflacion observada con la proyeccion trimestral

**Observado manda donde el BCRP publico.** El IPC de Lima sale alrededor del 1
del mes siguiente, asi que el mes mas reciente nunca lo tiene: ahi entra la
senda. La ventana de ajuste de la calibracion (202303-202506) es **toda
observada** -0 meses proyectados-, asi que ningun coeficiente se estimo sobre
proyeccion.

La senda trimestral se mensualiza con **desagregacion temporal estilo Denton**
(`Programas/analisis/00c_mensualiza_senda.py`): se interpola el PRECIO -que es
donde la suavidad tiene sentido- sujeto a que la tasa interanual resultante
reproduzca EXACTO el valor trimestral del BCRP. Medido sobre 14 trimestres:
**0.000000 pp de error**. Las alternativas fallan 0.023 (la heredada), 0.047
(lineal sobre la tasa) y 0.412 (interpolar el precio sin atar).

Dos consecuencias que importan:

- **El empalme no necesita add-factor.** El trimestre en curso tiene meses ya
  observados y entran DENTRO de la restriccion con su valor real, asi que la
  propia restriccion trimestral resuelve la union. Habia antes un re-anclaje con
  decaimiento: se quito porque apuntaba al reves y su horizonte no era medible.
- **Los efectos base sobreviven.** Marzo 2026 tuvo +2.3787% mensual -5.4
  desvios, la mayor en 32 anos, por la emergencia del gas de Camisea (INEI). Un
  metodo que interpole la tasa borra ese efecto; este lo respeta.

`macro_proy` marca cada fila: `0` si el F de su mes salio de inflacion
observada, `1` si de la senda. Hoy solo 202608 lleva 1, con `infl 4.3892%` y
`F -0.4228093335`.

**No se movio ningun coeficiente.** Verificado: los 12 BetaCal + corrimientos
probit, delta_0, driver, rho, lambda, CARGA, CENTRO y beta quedan identicos al
decimo decimal, y los 41 F de meses observados dan diferencia 0.00e+00 contra
lo commiteado.

## Orden de ejecucion

El piloto corrio en **70 segundos** (un mes, 26.4M filas) y con eso se
dimensionaron los demas a 6 meses (~420 s estimados, 47% del timeout de 900 s).

**HAY QUE REHACER DESDE EL DROP.** La tabla que dejo ese piloto tiene el esquema
viejo -llevaba `grupo_cal` y no `macro_proy`-, asi que un `INSERT INTO` desde
t02 falla por columnas. No se puede seguir desde t02.

Se dejo margen a proposito. Con `INSERT INTO` un TIMEOUT es peligroso: el limite
es del runner y no de Athena, asi que la insercion pudo completarse igual y
**relanzar duplicaria las filas sin avisar**. Es preferible un tramo de mas que
un tramo al borde.

El escalado deberia ser SUB-lineal: las ventanas de 360 `[M-6,M-1]` y PLIN
`[M-3,M-1]` se solapan entre meses del mismo tramo, asi que 6 meses no leen 6
veces las particiones de lookback. Es la misma razon por la que en el RCC pasar
de 6 a 24 meses costo 1.9x y no 4x.

| tramo | meses | statement | estado |
|---|---|---|---|
| t01 | 202401 | `CREATE TABLE` | **rehacer**: cambio el esquema |
| t02 | 202402-202407 | `INSERT INTO` | |
| t03 | 202408-202501 | `INSERT INTO` | |
| t04 | 202502-202507 | `INSERT INTO` | |
| t05 | 202508-202601 | `INSERT INTO` | |
| t06 | 202602-202607 | `INSERT INTO` | |
| t07 | 202608 | `INSERT INTO` | |

De a uno:

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/03_univ -Only 80_scr_univ_t02.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/03_univ -Only 80_scr_univ_t03.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/03_univ -Only 80_scr_univ_t04.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/03_univ -Only 80_scr_univ_t05.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/03_univ -Only 80_scr_univ_t06.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/03_univ -Only 80_scr_univ_t07.sql

**De a uno no es opcional.** El `catch` del runner no corta el lote: un fallo
genera errores en cascada y la causa raiz es siempre el primero.

**Si un tramo da TIMEOUT o error, NO relanzarlo de una.** Correr primero
`sql_val_univ/01_reconciliacion.sql` y mirar los meses de ese tramo: si ya tienen
las filas de la fuente, el INSERT se completo y relanzarlo duplicaria. Si no
aparecen, se puede relanzar.

## Al terminar

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_val_univ

- **01** reconcilia: `dif_filas = 0` en los 32 meses, `n_nodo_nulo = 0`
- **02** la matriz de migracion `grupo_cal_vigente` x `grupo_cal`. Es la que
  contesta cuanta gente cambia de decision de oferta
- **03** el evolutivo mensual y `dif_pp`, el cambio de nivel
- **04** de que se alimenta el nodo. Un N3 alto aca es lo esperado: las tres
  fuentes son internas de Interbank y esta PO es mucho mas ancha que su base

## La otra tabla

`scr_adm_vcnbank_tc_cal` es por alta y llega hasta 202606, lo que el RCC permite.
Sirve para lo que aca no se puede hacer: contrastar la PD contra la mora
observada. Las dos hacen falta y ninguna reemplaza a la otra.
