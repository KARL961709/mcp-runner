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

## Criterio de lectura

- `04` con `corr ~ 1` y `max_dif ~ 0` -> v5 es v4 reprocesada, los coeficientes
  transfieren y el scorer sale directo.
- `04` con `corr` en el orden de 0.9 -> es otro modelo y hay que reestimar.
