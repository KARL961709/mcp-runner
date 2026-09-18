-- QA[3] distribucion por grupo + personeria + PD (monotona)
SELECT grupos_cal, CASE WHEN tip_doc='1' THEN 'PN' ELSE 'PJ' END AS per, COUNT(*) AS n, ROUND(100*AVG(prob_modelo_cal),2) AS pd_prom
FROM disc_model_owner.admbank_prosp_202608 GROUP BY grupos_cal, CASE WHEN tip_doc='1' THEN 'PN' ELSE 'PJ' END ORDER BY 1,2
