-- escf_03_qa.sql | QA del entregable: n por p_codmes (debe cubrir 202501-202609, 202609 nuevo), avg esc opt, nulls. Agregado.
SELECT p_codmes, COUNT(*) AS n,
  ROUND(100*AVG(prob_modelo_cal_v2_opt),4) AS pd_opt_pct,
  SUM(CASE WHEN prob_modelo_cal_v2_opt IS NULL THEN 1 ELSE 0 END) AS opt_null
FROM disc_model_owner.scr_admbankbpe_rsk_cal_202501_202609
GROUP BY p_codmes ORDER BY p_codmes
