-- QA[4] distribucion por grupos_cal + PD promedio (debe ser monotona)
SELECT grupos_cal, COUNT(*) AS n, ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (),1) AS pct,
  ROUND(100*AVG(prob_modelo_cal),2) AS pd_prom
FROM disc_model_owner.b46029_scr_admbankbpe_cal_202608 GROUP BY grupos_cal ORDER BY grupos_cal
