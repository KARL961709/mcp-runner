-- ============================================================================
-- V10. Las columnas de control del _cal que ninguna otra query mira, y el grano
--      de 60_filtros. Corre DESPUES de 70_cal.
--      Un control declarado y nunca consultado es peor que no tenerlo: da la
--      sensacion de cobertura sin darla.
-- ============================================================================
SELECT
  SUBSTR(codmes_mrm, 1, 4)                                                        AS anio,
  COUNT(*)                                                                        AS n,
  SUM(falla_foto_t0)                                                              AS n_falla_foto_t0,
  SUM(falla_sin_target)                                                           AS n_sin_target,
  SUM(falla_scope_vs_v4)                                                          AS n_scope_vs_v4,
  SUM(falla_dup)                                                                  AS n_dup,
  SUM(CASE WHEN valida_colab = 0 THEN 1 ELSE 0 END)                               AS n_fuera_valida_colab,
  SUM(CASE WHEN valida_scope = 0 THEN 1 ELSE 0 END)                               AS n_fuera_valida_scope,
  SUM(CASE WHEN ctrl_asof_igual_codmes = 0 THEN 1 ELSE 0 END)                     AS n_asof_distinto,
  MAX(ctrl_n_cuentas)                                                             AS max_cuentas_por_cliente,
  SUM(CASE WHEN ctrl_n_filas_cierre IS NULL THEN 1 ELSE 0 END)                    AS n_sin_mes_en_cierre,
  SUM(falla_madurez_01)                                                           AS n_inmaduro_01,
  SUM(falla_madurez_03)                                                           AS n_inmaduro_03,
  SUM(falla_madurez_06)                                                           AS n_inmaduro_06,
  SUM(falla_madurez_09)                                                           AS n_inmaduro_09,
  SUM(falla_madurez_12)                                                           AS n_inmaduro_12,
  SUM(CASE WHEN falla_madurez_01 > falla_madurez_03 THEN 1 ELSE 0 END)            AS falla_madurez_no_monotona
FROM disc_model_owner.ds_stk_ree_pp_cal
GROUP BY 1
ORDER BY 1
