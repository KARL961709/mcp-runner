-- ============================================================================
-- E1d. COBERTURA DEL SCORE (pd_comppp_reen_itc) POR codmes
-- ============================================================================
SELECT
  CAST(codmes AS VARCHAR)                                                  AS codmes,
  COUNT(*)                                                                 AS n,
  COUNT(DISTINCT CAST(tip_doc AS VARCHAR) || '|' || CAST(key_value AS VARCHAR)) AS n_llaves,
  SUM(CASE WHEN pd_comppp_reen_itc IS NULL THEN 1 ELSE 0 END)              AS n_pd_null,
  SUM(CASE WHEN CAST(flg_reenganche AS INTEGER) = 1 THEN 1 ELSE 0 END)     AS n_reenganche,
  ROUND(AVG(CAST(pd_comppp_reen_itc AS DOUBLE)), 6)                        AS pd_prom,
  MIN(LENGTH(CAST(key_value AS VARCHAR)))                                  AS len_min_key,
  MAX(LENGTH(CAST(key_value AS VARCHAR)))                                  AS len_max_key
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov2_desencriptado
GROUP BY 1
ORDER BY 1
