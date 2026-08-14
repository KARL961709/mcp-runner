-- 03. DISTRIBUCION DEL SCORE POR MES Y ENTIDAD
--   monotonia y rango. Si el join del calendario macro fallara por tipo, todos
--   los meses saldrian con n_con_score = 0 y aca se veria de inmediato.
SELECT codmes_mrm,
       CASE WHEN entidad = '00002' THEN 'IBK' ELSE 'resto SS.FF.' END             AS grupo,
       COUNT(*)                                                                   AS n,
       SUM(CASE WHEN prob_modelo_cal IS NOT NULL THEN 1 ELSE 0 END)               AS n_con_score,
       MIN(puntuacion_cal)                                                        AS punt_min,
       APPROX_PERCENTILE(CAST(puntuacion_cal AS DOUBLE), 0.50)                    AS punt_p50,
       MAX(puntuacion_cal)                                                        AS punt_max,
       AVG(pd_raw)                                                                AS pd_raw_prom,
       AVG(prob_modelo_cal)                                                       AS pd_cal_prom
  FROM disc_model_owner.scr_adm_vcnbank_tc_cal
 GROUP BY 1, 2
 ORDER BY 1, 2
