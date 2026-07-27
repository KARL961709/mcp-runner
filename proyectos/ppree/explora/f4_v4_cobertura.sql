-- ============================================================================
-- F4. COBERTURA DE LA NUEVA FUENTE DE PD (v4) POR codmes, contando filas.
--     Solo usa codmes/tip_doc/key_value (comunes a toda la familia b39918).
-- ============================================================================
SELECT
  CAST(codmes AS VARCHAR)                                                       AS codmes,
  COUNT(*)                                                                      AS n,
  COUNT(DISTINCT CAST(tip_doc AS VARCHAR) || '|' || CAST(key_value AS VARCHAR))  AS n_llaves,
  MIN(LENGTH(CAST(key_value AS VARCHAR)))                                       AS len_min_key,
  MAX(LENGTH(CAST(key_value AS VARCHAR)))                                       AS len_max_key,
  COUNT(DISTINCT CAST(tip_doc AS VARCHAR))                                      AS n_dom_tip_doc
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
GROUP BY 1
ORDER BY 1
