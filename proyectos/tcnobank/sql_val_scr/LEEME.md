# sql_val_scr - QA de scr_adm_vcnbank_tc_cal

Read-only. Se puede correr por lote:

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_val_scr

Antes hay que construir la tabla, y eso va **de a uno**:

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/00_reset -Only r023_drop_71_scr_cal.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/02_gate  -Only 71_scr_cal.sql

## Que tiene que dar

| query | criterio |
|---|---|
| 01 | `dif_filas = 0` y las cinco `viol_*` en 0. `n_con_score = n_con_pdraw` |
| 02 | `n_discrepa = 0` en IBK. En el resto, `pct_sin_ninguna_fuente` alto es lo esperado, no un error |
| 03 | ningun mes con `n_con_score = 0` teniendo `pd_raw`. Puntuacion dentro de 0-1000 |
| 04 | `dif_pp` es el cambio de nivel contra la calibracion vigente |

Si 01 devuelve `viol_pdraw_sin_score > 0`, la causa esta en 03: mirar que mes
quedo sin `f_mes`.
