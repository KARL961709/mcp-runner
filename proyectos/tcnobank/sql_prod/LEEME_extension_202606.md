# Extension del ds_ a 202606 y reconstruccion del score

## Por que 202606 y no mas

Medido el 2026-08-14 contando filas por particion (no con `max()`, que cuenta
particiones declaradas y no meses con dato):

| fuente | ultimo mes completo | entra con | permite scorear hasta |
|---|---|---|---|
| `t_fact_report_rcc_rsk` | **202606** | el mes mismo | **202606** |
| `scr_vcnbank_rsk` | 202608 | el mes mismo | 202608 |
| `t_aws_360_cliente_mes_d3` | 202607 | [M-6, M-1] | 202608 |
| `t_agg_retail_user_trx_plin` | 202607 | [M-3, M-1] | 202608 |
| `t_rsk_cta_sueldo` | 202607 | M-1 | 202608 |

**El RCC amarra.** La poblacion es alta de TC derivada del RCC, asi que sin
202607 en `t_fact_report_rcc_rsk` no hay altas de 202607 que scorear.

PLIN tiene particion 202608 con 28,890,126 filas contra ~55M de un mes normal:
existe pero esta a medias. Con `max()` habria pasado por completo.

## Que se cambio

Dos literales, nada mas. `05_rcc_agg_t10` ya cubria 202601-202606 y el snapshot
de madurez de `50_targets` ya estaba en 202606.

- `01_staging/10_po.sql:25`  ventana de la poblacion  -> `'202606'`
- `01_staging/12_saldo_perfil.sql:24`  linea del alta -> `'202606'`

## Orden de ejecucion

Los DROP van en lote, son idempotentes:

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/00_reset

Los CREATE van **de a uno y en este orden**. El `catch` del runner no corta el
lote: si uno falla, los que siguen generan errores en cascada y la causa raiz es
siempre el primero. Parar al primer error.

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/01_staging -Only 10_po.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/01_staging -Only 11_po_key.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/01_staging -Only 12_saldo_perfil.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/01_staging -Only 13_pasivos.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/01_staging -Only 14_plin.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/01_staging -Only 15_cta_sueldo.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/01_staging -Only 16_nodo.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/01_staging -Only 20_rcc_base.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/01_staging -Only 21_rcc_flags.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/01_staging -Only 30_drivers.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/01_staging -Only 40_pdraw.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/01_staging -Only 50_targets.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/02_gate -Only 60_filtros.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/02_gate -Only 65_dedup.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/02_gate -Only 70_cal.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/02_gate -Only 71_scr_cal.sql

**NO correr `05_rcc_agg_t01..t10`**: son diez CTAS pesados sobre el RCC completo
y su tabla ya tiene 202606. Volver a correrlos solo gasta tiempo.

Los tramos `05_*` estan en la misma carpeta que los demas, asi que el `-Only` no
es opcional aca: sin el, el lote de `01_staging` los arrastraria.

## Despues

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_val_scr
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_val_frontera

La primera valida el score. La segunda deberia mostrar el `ds_` cerrando ya en
202606.

Lo que tiene que dar en `01_cobertura`: `dif_filas = 0`, las cinco `viol_*` en 0
y `n_con_score = n_con_pdraw`. En `03_distribucion` tiene que aparecer una fila
nueva de 202606 con `n_con_score > 0`.

## El F ya esta

`71_scr_cal.sql` trae 41 valores de F: los 39 del calendario mas 202606 y 202607,
calculados desde la inflacion OBSERVADA del BCRP (IPC PN38705PM, consultado el
2026-08-14). 202607 no va a tener filas hasta que el RCC lo publique -queda
listo para cuando pase-.
