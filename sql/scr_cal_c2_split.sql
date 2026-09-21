-- QA[2] split personeria x desc_cliente_der + PD promedio
SELECT CASE WHEN tip_doc='2' THEN 'PJ' ELSE 'PN' END AS per, desc_cliente_der, COUNT(*) AS n, ROUND(100*AVG(prob_modelo_cal),2) AS pd_cal, ROUND(100*AVG(pd_opt_v2),2) AS pd_v2 FROM disc_model_owner.b46029_scr_admbankbpe_cal_202608 GROUP BY 1,2 ORDER BY 1,2
