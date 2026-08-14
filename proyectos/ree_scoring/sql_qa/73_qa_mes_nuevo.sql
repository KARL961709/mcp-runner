-- 73. CONTROLES DEL CORTE NUEVO SOBRE SI MISMO
--   se corre DESPUES de 71. Lo que 72 no puede ver, porque 202608 no tiene
--   contraparte contra la cual compararse.
--   n debe dar 4,341,213 y n_meses 32. Todo viol_* distinto de 0 es FALLA.
SELECT CAST(codmes AS VARCHAR)                                                    AS codmes,
       COUNT(*)                                                                   AS n,
       SUM(CASE WHEN prob_modelo_cal IS NULL THEN 1 ELSE 0 END)                   AS viol_sin_prob,
       SUM(CASE WHEN trf_f_t IS NULL THEN 1 ELSE 0 END)                           AS viol_sin_ft,
       SUM(CASE WHEN CAST(puntuacion_cal AS INTEGER) < 0
                  OR CAST(puntuacion_cal AS INTEGER) > 1000
                THEN 1 ELSE 0 END)                                                AS viol_punt_rango,
       SUM(CASE WHEN CAST(puntuacion_cal AS INTEGER)
                  <> CAST(ROUND(1000.0 * (1.0 - CAST(prob_modelo_cal AS DOUBLE))) AS INTEGER)
                THEN 1 ELSE 0 END)                                                AS viol_punt_formula,
       COUNT(DISTINCT CAST(trf_f_t AS VARCHAR))                                   AS n_ft_distintos,
       MAX(CAST(trf_f_t AS DOUBLE))                                               AS ft,
       100.0 * SUM(CASE WHEN trf_tipo_ingreso_dep = 'DEP' THEN 1 ELSE 0 END)
             / COUNT(*)                                                           AS pct_dep,
       AVG(CAST(prob_modelo_cal AS DOUBLE))                                       AS prob_prom,
       AVG(CAST(puntuacion_cal AS DOUBLE))                                        AS punt_prom
  FROM disc_model_owner.scr_stk_ree_pp_cal_202608
 GROUP BY 1
 ORDER BY 1
