# Cadena SQL — construcción del maestro en Athena

Estas consultas construyen `disc_model_owner.ds_stk_ree_pp_cal`, el insumo único
de la calibración. **No las ejecuta el orquestador**: se corren en Athena y su
salida es el parquet que vive en `Data/`. El detalle de cada paso está en
`doc/SQL_PASO_A_PASO.md`.

Un solo statement por archivo (Athena no admite varios), UTF-8 sin BOM.

## Orden de ejecución

| carpeta | qué hace | cuándo |
|---|---|---|
| `00_reset/` | 20 `DROP` de las tablas intermedias | sólo para reconstruir desde cero |
| `01_staging/` | 14 pasos que arman población, filtros, target y drivers | siempre, en el orden del prefijo |
| `02_gate/` | consolida el maestro y exporta los cuatro parquets | después de staging |
| `03_qa/` | 11 verificaciones sobre lo construido | al cierre |

## `01_staging/` — orden por prefijo

```
10_po        universo comportamental PP
11_marca     perímetro reenganche (marca + puente CIF)
20_dm  21_gh  22_rf  23_cst  24_colab  25_sf  26_meses     insumos de t0
30_fut_a  30_fut_b  35_target                              ventana futura y target
40_drivers   ejes de segmentación
50_pd        PD del scorecard
```

## `02_gate/`

```
60_filtros   evalúa cada filtro
70_cal       consolida flg_scope_ree, flg_clean, flg_calib
90..93       exporta master, clean, dirty y macro
```

## `03_qa/`

`v1` a `v11`: cobertura y grano, reconciliación contra lo medido, rangos y
monotonía del target, drivers y PD, invarianza del ancla, fuentes de mora,
staging restante, reconciliación del gate, funnel con magnitud, controles del
maestro y grano de los filtros.

Cada verificación devuelve magnitud (`n`, `%`) además del veredicto: una
consulta que sólo dijera OK o FALLA no permite dimensionar el hallazgo.
