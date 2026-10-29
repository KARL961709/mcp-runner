-- ============================================================================
-- 11. QA de 10_score_2opciones_v0. Una fila por codmes mas la fila TOTAL.
--   Mide la cobertura de los insumos y el nivel de las seis probabilidades.
--   Un mes sin f_t queda sin PD de esa opcion: por eso se cuentan por separado,
--   el f_t de v1 usa 6 meses de porc_ipc y el de v2 necesita 15.
--   Solo agregados. Ninguna columna de identificacion de cliente.
-- ============================================================================
SELECT COALESCE(codmes, 'TOTAL')                                              AS codmes,
       COUNT(*)                                                               AS n,
       ROUND(100.0 * AVG(CAST(trf_falla_sin_tipo_ingreso AS DOUBLE)), 2)      AS pct_sin_tipo_ingreso,
       ROUND(100.0 * AVG(CASE WHEN trf_tipo_ingreso_dep = 'DEP' THEN 1.0 ELSE 0.0 END), 2) AS pct_dep,
       ROUND(100.0 * AVG(CASE WHEN trf_f_t_v1 IS NULL THEN 1.0 ELSE 0.0 END), 2) AS pct_sin_ft_v1,
       ROUND(100.0 * AVG(CASE WHEN trf_f_t_v2 IS NULL THEN 1.0 ELSE 0.0 END), 2) AS pct_sin_ft_v2,
       ROUND(MAX(trf_f_t_v1), 8)                                              AS ft_v1,
       ROUND(MAX(trf_f_t_v2), 8)                                              AS ft_v2,
       ROUND(100.0 * AVG(probabilidad), 4)                                    AS pd_raw_pct,
       ROUND(100.0 * AVG(prob_modelo_cal_v1), 4)                              AS cal_v1_pct,
       ROUND(100.0 * AVG(prob_modelo_cal_v2), 4)                              AS cal_v2_pct,
       ROUND(100.0 * AVG(prob_modelo_pit_v1), 4)                              AS pit_v1_pct,
       ROUND(100.0 * AVG(prob_modelo_pit_v2), 4)                              AS pit_v2_pct,
       ROUND(100.0 * AVG(prob_modelo_final_v1), 4)                            AS final_v1_pct,
       ROUND(100.0 * AVG(prob_modelo_final_v2), 4)                            AS final_v2_pct,
       SUM(CASE WHEN prob_modelo_cal_v2 IS NULL THEN 1 ELSE 0 END)            AS n_cal_v2_nulo,
       SUM(CASE WHEN prob_modelo_final_v2 <= 0.0003 THEN 1 ELSE 0 END)        AS n_en_piso_v2
FROM disc_model_owner.scr_stk_ree_pp_cal_2opc_v0
GROUP BY GROUPING SETS ((codmes), ())
ORDER BY 1
