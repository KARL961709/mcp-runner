-- QA[3] rangos + cobertura flg_cruce por personeria
SELECT CASE WHEN cod_tip_doc='2' THEN 'PJ' ELSE 'PN' END AS personeria,
  COUNT(*) AS n, ROUND(100.0*AVG(flg_cruce),1) AS pct_cruce,
  ROUND(100*MIN(pd_pit_final),3) AS min_pitf, ROUND(100*MAX(pd_pit_final),3) AS max_pitf,
  ROUND(100*MIN(pd_v2_esc_opt),3) AS min_v2, ROUND(100*MAX(pd_v2_esc_opt),3) AS max_v2
FROM disc_model_owner.b46029_desemb_maestra_202609 GROUP BY 1 ORDER BY 1
