-- ============================================================================
-- v26. FT y PD CALIBRADA DESPLEGADOS, directo de la tabla de scoreo
--   La fuente nueva trae trf_macro01/02 y prob_modelo_cal ya calculados por
--   produccion, mas las variantes _freeze y _smacro. En vez de reconstruir el
--   ft desde series de inflacion, se lee el valor real y se compara.
--   Agregado por cod_mes: no vuelve ninguna fila de cliente.
-- ============================================================================
SELECT
  CAST(cod_mes AS VARCHAR)                                     AS cod_mes,
  COUNT(*)                                                     AS n,
  COUNT(DISTINCT grupo_calibracion)                            AS n_grupos_cal,
  ROUND(AVG(trf_macro01), 8)                                   AS ft01_medio,
  ROUND(MIN(trf_macro01), 8)                                   AS ft01_min,
  ROUND(MAX(trf_macro01), 8)                                   AS ft01_max,
  ROUND(AVG(trf_macro02), 8)                                   AS ft02_medio,
  ROUND(AVG(trf_macro01_freeze), 8)                            AS ft01_freeze_medio,
  ROUND(100.0 * AVG(prob_modelo), 4)                           AS pd_raw_media_pct,
  ROUND(100.0 * AVG(prob_modelo_cal), 4)                       AS pd_cal_media_pct,
  ROUND(100.0 * AVG(prob_modelo_cal_freeze), 4)                AS pd_cal_freeze_media_pct,
  ROUND(100.0 * AVG(prob_modelo_cal_smacro), 4)                AS pd_cal_smacro_media_pct
FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610
WHERE CAST(cod_mes AS VARCHAR) >= '202504'
GROUP BY CAST(cod_mes AS VARCHAR)
ORDER BY 1
