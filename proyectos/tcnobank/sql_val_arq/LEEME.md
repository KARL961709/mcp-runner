# sql_val_arq — el arquetipo de salud fuera de Interbank

Read-only. Se puede correr por lote:

    .\Go.ps1 -SqlDir proyectos/tcnobank/sql_val_arq -TimeoutSec 1800

## Por que existe

El driver `seg_arq_salud = 'C'` se ajusto sobre **IBK solo**: los dos parquets
locales tienen `entidad = ['00002']` y ahi se acaba el analisis que se puede
hacer en la fabrica. En Athena la tabla `ds_adm_vcnbank_tc_cal` **si** trae las
25 entidades, y `scr_adm_vcnbank_tc_cal` trae el score calibrado para todas.
Estas cuatro consultas son la unica forma de contestar si el arquetipo dice algo
fuera de Interbank.

## Que contesta cada una

| # | pregunta |
|---|----------|
| q01 | ¿existe el arquetipo fuera de IBK? Cobertura y nulos por entidad |
| q02 | ¿separa riesgo? RD 12m por celda, IBK vs panel vs resto, en cohortes maduras |
| q03 | ¿el corrimiento de la celda C sirve fuera? Brecha con y sin el driver |
| q04 | ¿la senal sobrevive al condicionar por nodo? |

## Tres cosas que hay que leer con cuidado

**El arquetipo llega por un mapa de Interbank.** `seg_arq_salud` sale de
`e_perm_aws.t_inca_sa` y se pega por `t_mst_inter_ibk_base_cliente`, que es la
base de clientes de IBK. Quien no es cliente de IBK no tiene `inter_party_id` y
por lo tanto **no puede** tener arquetipo. q01 mide de cuanto es el agujero.

**`flg_clean` no sirve para mirar SS.FF.** Manda al 99 a toda entidad fuera del
panel de cinco (`f_entidades`), asi que fuera del panel no hay bucket limpio.
Las consultas reconstruyen `clean_sf` = el mismo `flg_clean` sin `f_entidades`,
y q02 verifica en su propia salida que sobre IBK reproduce `flg_clean` exacto
(`chk_ibk_igual` tiene que salir 0).

**Quitar el driver es exacto, re-anclar no.** El driver suma `-0.0350174239` al
probit antes del Vasicek, que divide entre `sqrt(1-rho) = 0.9832598843`.
Deshacerlo es sumar `0.0356135997` al probit de `prob_modelo_cal`, sin re-estimar
nada. Lo que **no** se puede hacer en SQL es re-ajustar `delta_0`, que en el paso
06 se optimiza junto con el driver. Por eso q03 trae `gap_rel_*`: la brecha de
cada celda menos la brecha global de su grupo, que es justo la parte que un
re-anclaje de nivel no puede mover. La comparacion de forma se lee ahi.

Todo se mide sobre **cohortes maduras** (`target_12m IS NOT NULL`).
