-- v02 cruce altas_ec_cal cortes usuario 978/949/891/869/840/766/720/674. RD/PD/pctN por nivel. EC ibk clean maduro 202501-202506.
SELECT nivel, COUNT(*) AS n,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_n,
       ROUND(AVG(target_12m) * 100, 2) AS rd_pct,
       ROUND(AVG(prob_modelo_cal) * 100, 2) AS pd_cal_pct
FROM (
  SELECT CASE WHEN puntuacion_modelo_cal IS NULL THEN 'Sin Nivel'
              WHEN puntuacion_modelo_cal >= 978 THEN '1.G1'
              WHEN puntuacion_modelo_cal >= 949 THEN '2.G2'
              WHEN puntuacion_modelo_cal >= 891 THEN '3.G3'
              WHEN puntuacion_modelo_cal >= 869 THEN '4.G4'
              WHEN puntuacion_modelo_cal >= 840 THEN '5.G5'
              WHEN puntuacion_modelo_cal >= 766 THEN '6.G6'
              WHEN puntuacion_modelo_cal >= 720 THEN '7.G7'
              WHEN puntuacion_modelo_cal >= 674 THEN '8.G8'
              ELSE '9.R' END AS nivel,
         target_12m, prob_modelo_cal
  FROM disc_model_owner.altas_ec_cal
  WHERE sub_producto = 'EC' AND flg_ibk = 1 AND flg_clean = 1
    AND target_12m IS NOT NULL
    AND codmes BETWEEN '202501' AND '202506'
)
GROUP BY nivel
ORDER BY nivel
