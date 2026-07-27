-- ============================================================================
-- G3. COBERTURA Y CONTRATO DE LA NUEVA FUENTE DE PD (v4).
--     Columna de documento = cod_tip_doc (no tip_doc): por eso fallo F4.
-- ============================================================================
SELECT
  CAST(codmes AS VARCHAR)                                                          AS codmes,
  COUNT(*)                                                                         AS n,
  COUNT(DISTINCT CAST(cod_tip_doc AS VARCHAR) || '|' || CAST(key_value AS VARCHAR)) AS n_llaves,
  SUM(CASE WHEN pd_comppp_reen_itc IS NULL THEN 1 ELSE 0 END)                      AS n_pd_null,
  SUM(CASE WHEN CAST(flg_reenganche AS INTEGER) = 1 THEN 1 ELSE 0 END)             AS n_reenganche,
  ROUND(MIN(CAST(pd_comppp_reen_itc AS DOUBLE)), 6)                                AS pd_min,
  ROUND(MAX(CAST(pd_comppp_reen_itc AS DOUBLE)), 6)                                AS pd_max,
  ROUND(AVG(CAST(pd_comppp_reen_itc AS DOUBLE)), 6)                                AS pd_prom,
  MIN(LENGTH(CAST(key_value AS VARCHAR)))                                          AS len_min_key,
  MAX(LENGTH(CAST(key_value AS VARCHAR)))                                          AS len_max_key,
  COUNT(DISTINCT CAST(cod_tip_doc AS VARCHAR))                                     AS n_dom_tip_doc
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
GROUP BY 1
ORDER BY 1
