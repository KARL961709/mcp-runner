# ppree / sql_diag — PD previa al desembolso

Todo lo de esta carpeta es **read-only** y se puede correr por lote.
Los dos `CREATE TABLE` viven aparte, en `../sql_diag_ctas/`, y se corren de a uno.

## La pregunta

La calibración de Reenganche pega `pd_raw` en el archivo `codmes_mrm + 1`, que es la
convención nativa del artefacto: el archivo rotulado `M` trae la foto del cierre de
`M-1`. Para el **stock** eso es correcto y es el par con el que el modelo se entrenó.

Para un **alta** esa foto es **posterior al desembolso**, porque el desembolso ocurre
durante `codmes_mrm`. La PD que generó el lead de campaña es la del archivo anterior.

No es un defecto de la fuente: la marca de reenganche coincide con el archivo correcto
en 15,226/15,226 (2024), 20,013/20,013 (2025) y 8,155/8,155 (2026). Lo que no coincide
es la convención mensual de un modelo de stock con el momento en que una campaña decide.

## Qué contesta cada query

| # | responde |
|---|---|
| 01 | cobertura: cuantas altas encuentran PD en la foto previa. **Nunca se midio** — H46 midio el flag, no la cobertura |
| 02 | Gini de `pd_pre` contra `pd_post` sobre el mismo target. Decide si hay que recalibrar o solo documentar |
| 03 | mora previa y re-reenganche: quien se vuelve a reenganchar y en que estado llega |
| 05 | EC por grupo usando la PD del mes (la del lead) |
| 06 | EC por grupo, PD del mes contra PD desfasada, lado a lado |
| 07 | EC por periodo y segmento |
| 08 | PD y `flg_reenganche` en archivo D contra D+1 por alta — las **marginales** |
| 09 | foto del cliente al cierre D-1 contra cierre D: saldo, cuentas y mora. Aca se ve si el desembolso ya aterrizo |
| 10 | target 12m de las altas en la cohorte D contra la D-1. **Da la LRA nueva**, que es lo que el re-fit necesita |

Complementan a las de `../sql_val/`:

| # | responde |
|---|---|
| v14 | **casos**: una alta por estrato, trazada de D-2 a D+1 sobre las cuatro fuentes |
| v15 | el **joint** `flg_reenganche` D x D+1, que no se deriva de las marginales de 08 |
| v16 | contrafactual del ancla D-1 sobre `ds_stk_ree_pp_cal`, sin construir nada |
| v17 | comparacion **pareada** pd lead vs pd calibracion por alta |

## Orden sugerido

1. **v17** y **v16** — son las que dan el numero que falta: el pareado y la LRA nueva.
   Corren sobre `ds_stk_ree_pp_cal`, que ya entra con las 90 cohortes.
2. **01** y **10** — cobertura y RD12 en las dos cohortes, desde las fuentes madre.
3. **v14**, **v15**, **08**, **09** — el mecanismo y su peso.
4. **02** — el Gini, que es el que decide si se recalibra.

## Tablas que leen

Ninguna se construye. Todas existen:

- `disc_model_owner.ds_stk_ree_pp_cal` — la tabla de calibracion, 90 cohortes
- `disc_model_owner.ds_stk_ree_pp_11_marca` — el perimetro reenganche
- `disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4` — la fuente de `pd_raw`
- `e_perm_aws.ds_flg_compppibk_rsk` — la madre del target
- `e_perm_aws.t_rsk_bkp_cierre_mensual` — el cierre mensual
- `d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp` — las altas
- `e_perm_aws.t_mst_ctaibk_rsk` — puente `cod_cuc` a `key_value`

## Correr

```
.\Go.ps1 -SqlDir proyectos/ppree/sql_diag
```

O un subconjunto. `-Only` compara el **basename exacto**, sin extension:

```
.\Go.ps1 -SqlDir proyectos/ppree/sql_val -Only v17_pd_lead_vs_calib_pareado,v16_ancla_dm1_contrafactual
```

## Ojo

- `11_export_pd_pre_madre.sql` lleva el placeholder `<S3_DATOS>`: solo lo sustituye el
  runner cuando hay `$S3Datos` definido. Sin eso falla.
- Las salidas quedan en `output/`, bloqueado por el `.gitignore` en lista blanca.
  De vuelta viaja `_resumen.txt`, no el dato.
