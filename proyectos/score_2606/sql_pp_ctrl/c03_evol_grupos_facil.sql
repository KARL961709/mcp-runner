-- c03 evolutivo niveles de riesgo PP Facil por mes (cortes 985/955/947/912/892/864, clean). pct_N por G + PD_cal media. Esta tabla NO trae target -> sin RD.
SELECT codmes,
       ROUND(100.0 * SUM(CASE WHEN nivel = 'G1' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_g1,
       ROUND(100.0 * SUM(CASE WHEN nivel = 'G2' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_g2,
       ROUND(100.0 * SUM(CASE WHEN nivel = 'G3' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_g3,
       ROUND(100.0 * SUM(CASE WHEN nivel = 'G4' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_g4,
       ROUND(100.0 * SUM(CASE WHEN nivel = 'G5' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_g5,
       ROUND(100.0 * SUM(CASE WHEN nivel = 'G6' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_g6,
       ROUND(100.0 * SUM(CASE WHEN nivel = 'GR' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_gr,
       ROUND(AVG(prob_modelo_cal_ppfacil) * 100, 2) AS pd_cal_facil_pct
FROM (
  SELECT codmes, prob_modelo_cal_ppfacil,
    CASE WHEN puntuacion_modelo_cal_ppfacil >= 985 THEN 'G1'
         WHEN puntuacion_modelo_cal_ppfacil >= 955 THEN 'G2'
         WHEN puntuacion_modelo_cal_ppfacil >= 947 THEN 'G3'
         WHEN puntuacion_modelo_cal_ppfacil >= 912 THEN 'G4'
         WHEN puntuacion_modelo_cal_ppfacil >= 892 THEN 'G5'
         WHEN puntuacion_modelo_cal_ppfacil >= 864 THEN 'G6'
         ELSE 'GR' END AS nivel
  FROM disc_model_owner.scr_admvc_pp_cal_202401_202608
  WHERE flg_clean = 1
)
GROUP BY codmes
ORDER BY codmes
