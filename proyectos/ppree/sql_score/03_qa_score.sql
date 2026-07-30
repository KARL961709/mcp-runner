-- ============================================================================
-- 81. QA de 80_score_stock_pp. Una fila por codmes mas la fila TOTAL.
--   Mide lo que hoy esta sin medir: que fraccion del stock queda sin dato de
--   situacion laboral y por lo tanto cae a NO DEP por el COALESCE, y que
--   fraccion queda sin f_t y por lo tanto sin PD calibrada.
--   Solo agregados. Ninguna columna de identificacion de cliente.
-- ============================================================================
SELECT COALESCE(codmes, 'TOTAL')                                          AS codmes,
       COUNT(*)                                                           AS n,
       ROUND(100.0 * AVG(CAST(trf_falla_sin_tipo_ingreso AS DOUBLE)), 2)  AS pct_sin_tipo_ingreso,
       ROUND(100.0 * AVG(CAST(trf_falla_sin_cta_sueldo AS DOUBLE)), 2)    AS pct_sin_cta_sueldo,
       ROUND(100.0 * AVG(CASE WHEN trf_tipo_ingreso_dep = 'DEP' THEN 1.0 ELSE 0.0 END), 2) AS pct_dep,
       ROUND(100.0 * AVG(CASE WHEN trf_tipo_ingreso = 'MIXTO' THEN 1.0 ELSE 0.0 END), 2)   AS pct_mixto,
       ROUND(100.0 * AVG(CASE WHEN trf_flg_cs_estado = 'SIN_DATO' THEN 1.0 ELSE 0.0 END), 2) AS pct_cs_sin_dato,
       ROUND(100.0 * AVG(CASE WHEN prob_modelo_cal IS NULL THEN 1.0 ELSE 0.0 END), 2)      AS pct_sin_pd_cal,
       ROUND(MAX(trf_f_t), 6)                                             AS f_t,
       ROUND(100.0 * AVG(probabilidad), 4)                                AS pd_raw_pct,
       ROUND(100.0 * AVG(prob_modelo_cal), 4)                             AS pd_cal_pct,
       ROUND(AVG(prob_modelo_cal) / NULLIF(AVG(probabilidad), 0), 4)      AS ratio_cal_raw,
       MIN(puntuacion_cal)                                                AS punt_cal_min,
       MAX(puntuacion_cal)                                                AS punt_cal_max
FROM disc_model_owner.ds_stk_ree_pp_80_score
GROUP BY GROUPING SETS ((codmes), ())
ORDER BY 1
