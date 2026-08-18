-- 03. EVOLUTIVO POR MES
--   nivel de la PD nueva contra la vigente, y composicion bajo los cortes de la
--   opcion B. dif_pp es cuanto mueve el nivel el reemplazo.
--   macro_proy marca los meses cuyo F salio de inflacion PROYECTADA y no
--   observada: hoy solo el ultimo. Va en la salida para que no se lean igual
SELECT p_codmes                                                                  AS codmes,
       MAX(macro_proy)                                                           AS macro_proy,
       COUNT(*)                                                                  AS n,
       AVG(pd_raw)                                                               AS pd_raw_prom,
       AVG(pd_cal_vigente)                                                       AS cal_vigente_prom,
       AVG(prob_modelo_cal)                                                      AS cal_nueva_prom,
       100.0 * (AVG(prob_modelo_cal) - AVG(pd_cal_vigente))                      AS dif_pp,
       100.0 * SUM(CASE WHEN puntuacion_cal >= 972 THEN 1 ELSE 0 END) / COUNT(*) AS pct_g1,
       100.0 * SUM(CASE WHEN puntuacion_cal >= 964 AND puntuacion_cal < 972
                        THEN 1 ELSE 0 END) / COUNT(*)                            AS pct_g2,
       100.0 * SUM(CASE WHEN puntuacion_cal >= 938 AND puntuacion_cal < 964
                        THEN 1 ELSE 0 END) / COUNT(*)                            AS pct_g3,
       100.0 * SUM(CASE WHEN puntuacion_cal >= 899 AND puntuacion_cal < 938
                        THEN 1 ELSE 0 END) / COUNT(*)                            AS pct_g4,
       100.0 * SUM(CASE WHEN puntuacion_cal >= 768 AND puntuacion_cal < 899
                        THEN 1 ELSE 0 END) / COUNT(*)                            AS pct_g5,
       100.0 * SUM(CASE WHEN puntuacion_cal < 768 THEN 1 ELSE 0 END) / COUNT(*)  AS pct_r
  FROM disc_model_owner.scr_univ_vcnbank_tc_cal
 GROUP BY p_codmes
 ORDER BY 1
