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
senda proyectada. La ventana de ajuste de la calibracion (202303-202506) es
**toda observada** -0 meses proyectados-, asi que ningun coeficiente se estimo
sobre proyeccion.

La senda trimestral se ancla en el **mes central de cada trimestre**, con
valores redondos, y los meses intermedios vienen interpolados:

    202608=4.25   202611=4.56   202702=4.45   202705=4.10   202708=3.65

Con que se interpola **no se pudo reproducir**: lineal falla por 0.050 pp,
spline cubica por 0.029 y PCHIP por 0.024. Queda como incognita del insumo.

### El empalme se RE-ANCLA, no se pega crudo

La senda se armo con un corte anterior, asi que en los meses que despues
cerraron tiene un error de pronostico medible: en 202607 dijo 4.1330% y el real
vino 4.0652%, **-0.0678 pp**. Pegarla cruda convierte ese error en un escalon
que no existe:

| | salto 202607 -> 202608 |
|---|---|
| empalme crudo | +0.1848 pp |
| **re-anclado** | **+0.1170 pp** (el paso que la propia senda preveia) |

Se corrige entero en el primer mes proyectado y se disuelve linealmente en 6,
para no arrastrar nuestro error sobre el nivel de largo plazo, que es del BCRP:

| mes | infl usada | senda cruda | corrimiento |
|---|---|---|---|
| 202608 | 4.1822% | 4.2500% | -0.0678 |
| 202609 | 4.3271% | 4.3836% | -0.0565 |
| 202612 | 4.5213% | 4.5439% | -0.0226 |
| 202702 | 4.4500% | 4.4500% | 0.0000 |

`infl_BASE/PESIMISTA/OPTIMISTA` conservan la senda **cruda**: el re-anclaje vive
solo en `infl`, que es la que lee el paso 03.

### macro_proy

Cada fila lleva **`macro_proy`**: `0` si el F de su mes salio de inflacion
observada, `1` si de proyeccion. Hoy solo 202608 lleva 1.

## Orden de ejecucion

El piloto **ya corrio**: t01, un mes, 26.4M filas, **70 segundos**. Con eso se
dimensionaron los demas a 6 meses (~420 s estimados, 47% del timeout de 900 s).

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
| t01 | 202401 | `CREATE TABLE` | **corrido, 70 s** |
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
