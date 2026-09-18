-- QA[3] split NUEVO/RECURRENTE derivado, por personeria + rango de prob
SELECT CASE WHEN tip_doc='1' THEN 'PN' ELSE 'PJ' END AS per, desc_cliente_cal, COUNT(*) AS n,
  ROUND(100*AVG(prob_modelo_cal),3) AS pd_prom
FROM disc_model_owner.b46029_scr_admbankbpe_cal_202608 GROUP BY 1,2 ORDER BY 1,2
