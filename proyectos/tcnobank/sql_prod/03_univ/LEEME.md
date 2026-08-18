# 03_univ - la calibracion sobre la poblacion objetivo

Tabla `disc_model_owner.scr_univ_vcnbank_tc_cal`. Una fila por cada fila de
`scr_vcnbank_rsk` en **202401 a 202607** (31 meses, ~800M filas), con
`prob_modelo_cal`, `puntuacion_cal` y `grupo_cal` = **nuestra** calibracion.
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
| `grupo_cal` | `grupo_cal_vigente` |

`grupo_cal` trae los cortes de la opcion B ya aplicados: `972 | 964 | 938 | 899 | 768`.

## Por que la ventana termina en 202607

`scr_vcnbank_rsk` llega a 202608, pero el factor macro no: F sale de la inflacion
observada y el BCRP publica el IPC de agosto alrededor del 1 de septiembre.
Meter 202608 ahora daria un mes entero con `prob_modelo_cal` nulo. Cuando salga
el dato es un tramo mas.

## Orden de ejecucion

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/00_reset -Only r024_drop_scr_univ.sql

Despues **el piloto, y cronometrado**:

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/03_univ -Only 80_scr_univ_t01.sql

Un solo mes, 202401, ~26.4M filas. **Anotar los segundos del `_resumen.txt` y
pegarlos de vuelta antes de seguir.** Los diez tramos que siguen son de 3 meses:
si el piloto tarda X, cada uno deberia tardar del orden de 3X, y si eso pasa el
timeout del runner (900s por defecto) hay que regenerarlos mas chicos ANTES de
lanzarlos, no descubrirlo a mitad de camino.

Con el tiempo confirmado, los diez restantes **de a uno y en orden**:

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/03_univ -Only 80_scr_univ_t02.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/03_univ -Only 80_scr_univ_t03.sql
    ... hasta t11

| tramo | meses | statement |
|---|---|---|
| t01 | 202401 | `CREATE TABLE` (crea la tabla) |
| t02 | 202402-202404 | `INSERT INTO` |
| t03 | 202405-202407 | `INSERT INTO` |
| t04 | 202408-202410 | `INSERT INTO` |
| t05 | 202411-202501 | `INSERT INTO` |
| t06 | 202502-202504 | `INSERT INTO` |
| t07 | 202505-202507 | `INSERT INTO` |
| t08 | 202508-202510 | `INSERT INTO` |
| t09 | 202511-202601 | `INSERT INTO` |
| t10 | 202602-202604 | `INSERT INTO` |
| t11 | 202605-202607 | `INSERT INTO` |

**De a uno no es opcional.** El `catch` del runner no corta el lote: un fallo
genera errores en cascada y la causa raiz es siempre el primero. Y con
`INSERT INTO` hay un riesgo que el CTAS no tiene — **correr un tramo dos veces
duplica sus filas sin avisar**. Por eso la QA reconcilia contra la fuente mes a
mes: `dif_filas` distinto de 0 delata tanto el tramo que falto como el repetido.

## Al terminar

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_val_univ

- **01** reconcilia: `dif_filas = 0` en los 31 meses, `n_nodo_nulo = 0`
- **02** la matriz de migracion `grupo_cal_vigente` x `grupo_cal`. Es la que
  contesta cuanta gente cambia de decision de oferta
- **03** el evolutivo mensual y `dif_pp`, el cambio de nivel
- **04** de que se alimenta el nodo. Un N3 alto aca es lo esperado: las tres
  fuentes son internas de Interbank y esta PO es mucho mas ancha que su base

## La otra tabla

`scr_adm_vcnbank_tc_cal` es por alta y llega hasta 202606, lo que el RCC permite.
Sirve para lo que aca no se puede hacer: contrastar la PD contra la mora
observada. Las dos hacen falta y ninguna reemplaza a la otra.
