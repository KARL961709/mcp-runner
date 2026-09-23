-- cmp_escopt_cov.sql | cobertura de la ENVIADA por p_codmes (INT) + avg esc opt/base. Agregado.
SELECT p_codmes, COUNT(*) AS n,
  ROUND(100*AVG(prob_modelo_cal_v2_opt),4) AS pd_opt_pct,
  ROUND(100*AVG(prob_modelo_cal_v2),4) AS pd_base_pct
FROM d_perm_aws.scr_admbankbpe_rsk_cal_202501_202608 WHERE p_codmes >= 202606 GROUP BY p_codmes ORDER BY p_codmes
