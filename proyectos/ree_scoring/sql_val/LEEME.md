# ree_scoring — indagacion previa al scorer de stock

Lote de solo lectura. No crea ni modifica tablas.

```
.\Go.ps1 -SqlDir proyectos\ree_scoring\sql_val
```

## Que se esta decidiendo

La calibracion de Reenganche (ENTREGA_REE_FINAL) se estimo sobre la **v4**
(`t_b39918_scr_stockpp_itc_reen_reprocesov4`). La tabla que se quiere scorear es
la **v5** (`t_b39918_scr_stockpp_itc_reprocesov5`), que no figura en el proyecto.

Precedente H106/A48: al pasar de v2 a v4 la pd cambio de scorecard (corr 0.9096,
max_dif 0.473) y hubo que **reestimar** BetaCal, delta probit, rho y lambda. Este
lote mide si v5 repite ese caso o si es la misma cosecha que v4.

## Que responde cada query

| query | pregunta |
|---|---|
| `01_columnas` | existe la v5, como se llaman sus columnas, y si trae `tipo_ingreso` (el unico driver que la PD necesita) |
| `02_v5_cobertura` | que meses son scoreables y si hay pd fuera de (0,1) |
| `03_llave_unicidad` | si `key_value + codmes` basta como llave, o hace falta el tipo de documento |
| `04_v4_vs_v5` | **el que decide**: corr y max_dif de la pd cruda sobre la interseccion |
| `05_bcrp_ipc_serie` | si `porc_ipc` reproduce el parquet macro, y que meses agrega |
| `06_bcrp_ipc_rango` | desde cuando existe la serie en la tabla gobernada |

`01` es el unico que no depende de que los nombres de columna sean los esperados.
Si `02`, `03` o `04` fallan, el motivo en `_resumen.txt` dice que columna falta y
se corrige con lo que devuelva `01`; el lote no se corta por eso.

## Segunda tanda: que hay que actualizar

`01`-`06` cerraron que v5 es v4 bit a bit (corr 1, max_dif 0, las 3.948.959 filas
identicas) y que `porc_ipc` reproduce el parquet macro exacto. Estas tres miden
que falta refrescar, empezando por la fuente madre.

| query | pregunta | peso |
|---|---|---|
| `07_driver_cobertura_v5` | que porcentaje de la v5 queda con `tipo_ingreso` conocido, mes a mes, y si la composicion DEP salta en 202604-202605 por H66 | la mas pesada del lote |
| `08_fuentes_madre_rango` | hasta donde llega hoy cada fuente madre contra su cobertura declarada el 2026-07-27 | media |
| `09_castigo_rango` | idem para la fuente de castigo, aparte porque su llave es fecha | baja |

`08` es el que decide si conviene recalibrar: la frontera de madurez de 12 meses
sale de hasta donde llegue `t_rsk_bkp_cierre_mensual`. Declarada 202606, que es
la que fijo `COHORTE_FIN = 202506`.

`07` no cambia ningun coeficiente, pero decide cuanta poblacion se scorea con el
driver medido y cuanta por defecto: `tipo_ingreso` elige cual de las dos BetaCal
se aplica, asi que un hueco de cobertura no es un dato faltante, es un cambio de
calibrador.

## Criterio de lectura

- `04` con `corr ~ 1` y `max_dif ~ 0` -> v5 es v4 reprocesada, los coeficientes
  transfieren y el scorer sale directo.
- `04` con `corr` en el orden de 0.9 -> es otro modelo y hay que reestimar.
