-- ============================================================================
-- v21. CATALOGO de tablas de score reenganche que EXISTEN hoy
--   scr_stk_ree_pp_cal_202607 lleva el mes en el nombre: es una por corrida.
--   Antes de asumir donde vive la pd de las cohortes nuevas, se listan.
--   La cobertura por mes de las dos hermanas v4 la mide v12_alcance_score.
-- ============================================================================
SELECT
  table_schema,
  table_name,
  COUNT(*)                                                                AS n_columnas,
  SUM(CASE WHEN column_name = 'pd_comppp_reen_itc' THEN 1 ELSE 0 END)     AS tiene_pd_reen,
  SUM(CASE WHEN column_name = 'probabilidad' THEN 1 ELSE 0 END)           AS tiene_probabilidad,
  SUM(CASE WHEN column_name = 'prob_modelo_cal' THEN 1 ELSE 0 END)        AS tiene_prob_cal,
  SUM(CASE WHEN column_name = 'puntuacion_cal' THEN 1 ELSE 0 END)         AS tiene_punt_cal,
  SUM(CASE WHEN column_name = 'trf_f_t' THEN 1 ELSE 0 END)                AS tiene_ft,
  SUM(CASE WHEN column_name IN ('codmes', 'cod_mes') THEN 1 ELSE 0 END)   AS tiene_codmes
FROM information_schema.columns
WHERE table_schema IN ('disc_riesgos', 'd_perm_aws', 'disc_model_owner', 'e_perm_aws')
  AND (table_name LIKE '%scr_stk_ree%'
       OR table_name LIKE '%scr_stockpp%'
       OR table_name LIKE '%cppibkren%')
GROUP BY table_schema, table_name
ORDER BY 1, 2
