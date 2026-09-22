-- desemb_corr_c3_cober.sql | cobertura del cruce corregido por personeria: n, pct con pd_raw, pct con prob_modelo. Agregado.
SELECT CASE WHEN cod_tip_doc='2' THEN 'PJ' ELSE 'PN' END AS personeria,
  COUNT(*) AS n,
  ROUND(100.0*SUM(CASE WHEN pd_raw IS NOT NULL THEN 1 ELSE 0 END)/COUNT(*),1) AS pct_pd_raw,
  ROUND(100.0*SUM(CASE WHEN prob_modelo IS NOT NULL THEN 1 ELSE 0 END)/COUNT(*),1) AS pct_prob_modelo
FROM disc_model_owner.b46029_desemb_cal_corr_202609
GROUP BY 1 ORDER BY 1
