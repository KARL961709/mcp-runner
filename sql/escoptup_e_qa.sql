-- escoptup_e_qa.sql | QA cobertura por p_codmes: n, avg prob_modelo_cal, avg prob_modelo_esc_opt, nulls. Debe traer 202607/202608/202609. Agregado.
SELECT p_codmes, COUNT(*) AS n,
  ROUND(100*AVG(prob_modelo_cal),4) AS pd_cal_pct,
  ROUND(100*AVG(prob_modelo_esc_opt),4) AS pd_escopt_pct,
  SUM(CASE WHEN prob_modelo_cal IS NULL THEN 1 ELSE 0 END) AS cal_null,
  SUM(CASE WHEN prob_modelo_esc_opt IS NULL THEN 1 ELSE 0 END) AS escopt_null
FROM disc_model_owner.scr_admbankbpe_calibrado_202609_escopt
GROUP BY p_codmes ORDER BY p_codmes
