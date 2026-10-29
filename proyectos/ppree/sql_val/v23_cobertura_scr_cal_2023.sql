-- ============================================================================
-- v23. COBERTURA de la fuente NUEVA de pd_raw, contando filas
--   El comentario del 50_pd declara 202301-202610. Se mide desde 202504.
--   El grano declarado del join es (cod_mes, cod_tip_doc, key_value): si n_filas
--   supera n_llaves_doc, el LEFT JOIN del 50_pd multiplica filas.
-- ============================================================================
SELECT
  CAST(cod_mes AS VARCHAR)                                                AS cod_mes,
  COUNT(*)                                                                AS n_filas,
  COUNT(DISTINCT CAST(key_value AS VARCHAR) || '|' || CAST(cod_tip_doc AS VARCHAR)) AS n_llaves_doc,
  COUNT(prob_modelo)                                                      AS n_prob_modelo,
  SUM(CASE WHEN prob_modelo > 0 AND prob_modelo < 1 THEN 1 ELSE 0 END)    AS n_prob_rango,
  ROUND(100.0 * AVG(prob_modelo), 4)                                      AS prob_media_pct,
  ROUND(MIN(prob_modelo), 8)                                              AS prob_min,
  ROUND(MAX(prob_modelo), 8)                                              AS prob_max,
  COUNT(puntuacion)                                                       AS n_puntuacion,
  ROUND(AVG(CAST(puntuacion AS DOUBLE)), 2)                               AS punt_media
FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610
WHERE CAST(cod_mes AS VARCHAR) >= '202504'
GROUP BY CAST(cod_mes AS VARCHAR)
ORDER BY 1
