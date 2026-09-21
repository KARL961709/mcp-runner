-- QA[3] distribucion por grupos_cal + rangos
SELECT grupos_cal, COUNT(*) AS n, ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (),1) AS pct, ROUND(100*MIN(prob_modelo_cal),3) AS min_pd, ROUND(100*MAX(prob_modelo_cal),3) AS max_pd FROM disc_model_owner.b46029_scr_admbankbpe_cal_202608 GROUP BY grupos_cal ORDER BY grupos_cal
