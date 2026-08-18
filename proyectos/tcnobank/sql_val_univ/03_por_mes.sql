-- 03. EVOLUTIVO POR MES
--   nivel de la PD nueva contra la vigente, y composicion de la cartera bajo
--   los cortes de la opcion B. dif_pp es cuanto mueve el nivel el reemplazo
SELECT p_codmes                                                                  AS codmes,
       COUNT(*)                                                                  AS n,
       AVG(pd_raw)                                                               AS pd_raw_prom,
       AVG(pd_cal_vigente)                                                       AS cal_vigente_prom,
       AVG(prob_modelo_cal)                                                      AS cal_nueva_prom,
       100.0 * (AVG(prob_modelo_cal) - AVG(pd_cal_vigente))                      AS dif_pp,
       100.0 * SUM(CASE WHEN grupo_cal = 'G1' THEN 1 ELSE 0 END) / COUNT(*)      AS pct_g1,
       100.0 * SUM(CASE WHEN grupo_cal = 'G2' THEN 1 ELSE 0 END) / COUNT(*)      AS pct_g2,
       100.0 * SUM(CASE WHEN grupo_cal = 'G3' THEN 1 ELSE 0 END) / COUNT(*)      AS pct_g3,
       100.0 * SUM(CASE WHEN grupo_cal = 'G4' THEN 1 ELSE 0 END) / COUNT(*)      AS pct_g4,
       100.0 * SUM(CASE WHEN grupo_cal = 'G5' THEN 1 ELSE 0 END) / COUNT(*)      AS pct_g5,
       100.0 * SUM(CASE WHEN grupo_cal = 'R'  THEN 1 ELSE 0 END) / COUNT(*)      AS pct_r
  FROM disc_model_owner.scr_univ_vcnbank_tc_cal
 GROUP BY p_codmes
 ORDER BY 1
