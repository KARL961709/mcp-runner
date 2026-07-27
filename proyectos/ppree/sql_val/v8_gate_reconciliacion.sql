-- ============================================================================
-- V8. G1 - LA RECONCILIACION DEL GATE. Corre DESPUES de 70_cal.
--     #99 + #1 + #0 debe dar el universo del codmes, sin solape y sin resto.
--     falla_bucket_fuera_dominio: flg_clean solo puede ser 99, 1 o 0. El 98 no existe.
--     falla_calib_en_99: flg_calib = 1 exige flg_clean <> 99.
--     falla_calib_sin_pd / sin_madurez: los otros dos terminos del eje.
--     Escrita antes de ver un solo numero del gate.
-- ============================================================================
SELECT
  codmes_mrm,
  COUNT(*)                                                                        AS n_universo,
  SUM(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END)                                 AS n_99,
  SUM(CASE WHEN flg_clean = 1  THEN 1 ELSE 0 END)                                 AS n_1,
  SUM(CASE WHEN flg_clean = 0  THEN 1 ELSE 0 END)                                 AS n_0,
  COUNT(*) - SUM(CASE WHEN flg_clean IN (99, 1, 0) THEN 1 ELSE 0 END)             AS falla_bucket_fuera_dominio,
  COUNT(*) - ( SUM(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END)
             + SUM(CASE WHEN flg_clean = 1  THEN 1 ELSE 0 END)
             + SUM(CASE WHEN flg_clean = 0  THEN 1 ELSE 0 END) )                  AS falla_reconciliacion,
  SUM(CASE WHEN flg_calib = 1 AND flg_clean = 99 THEN 1 ELSE 0 END)               AS falla_calib_en_99,
  SUM(CASE WHEN flg_calib = 1 AND falla_cruce_pd = 1 THEN 1 ELSE 0 END)           AS falla_calib_sin_pd,
  SUM(CASE WHEN flg_calib = 1 AND falla_madurez_12 = 1 THEN 1 ELSE 0 END)         AS falla_calib_sin_madurez,
  SUM(CASE WHEN flg_calib = 1 AND falla_dup = 1 THEN 1 ELSE 0 END)                AS falla_calib_con_dup,
  SUM(flg_scope_ree)                                                              AS n_ree,
  SUM(CASE WHEN flg_scope_ree = 1 AND flg_clean = 1 AND flg_calib = 1 THEN 1 ELSE 0 END) AS n_fit
FROM disc_model_owner.ds_stk_ree_pp_cal
GROUP BY 1
ORDER BY 1
