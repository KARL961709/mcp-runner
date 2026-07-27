-- ============================================================================
-- F2a. ARTEFACTO VIGENTE disc_model_owner.enr_comp_pp_ree_cal  (el que exporta
--      Fase 2). Existe todavia con filas? Cuadra con los 97,816 del doc?
-- ============================================================================
SELECT
  SUBSTR(CAST(codmes AS VARCHAR), 1, 4)                                    AS anio,
  COUNT(*)                                                                 AS n,
  SUM(CASE WHEN flg_calib = 1 THEN 1 ELSE 0 END)                           AS n_calib,
  SUM(CASE WHEN flg_calib = 1 AND flg_cruce_pd = 1 THEN 1 ELSE 0 END)      AS n_calib_con_pd,
  SUM(CASE WHEN flg_calib = 1 THEN target_12m_60 END)                      AS def12,
  COUNT(DISTINCT CAST(codmes AS VARCHAR))                                  AS n_meses_con_filas,
  MIN(CAST(codmes AS VARCHAR))                                             AS mes_min,
  MAX(CAST(codmes AS VARCHAR))                                             AS mes_max
FROM disc_model_owner.enr_comp_pp_ree_cal
GROUP BY 1
ORDER BY 1
