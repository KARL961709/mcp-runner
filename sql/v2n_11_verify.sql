-- v2n_f_verify.sql | VERIFICA que el v2native rebuilt reproduce lo enviado en 202607/202608 (mae~0) y da cobertura 202609 (nuevo, sin enviada = NULL). Agregado.
SELECT o.p_codmes, COUNT(*) AS n,
  ROUND(100*AVG(o.prob_modelo_cal_v2),4) AS pd_v2_new,
  ROUND(100*AVG(s.prob_modelo_cal_v2),4) AS pd_v2_env,
  ROUND(1000*AVG(ABS(o.prob_modelo_cal_v2 - s.prob_modelo_cal_v2)),4) AS mae_v2_x10,
  ROUND(100*AVG(o.prob_modelo_cal_v2_opt),4) AS pd_opt_new,
  ROUND(100*AVG(s.prob_modelo_cal_v2_opt),4) AS pd_opt_env,
  ROUND(1000*AVG(ABS(o.prob_modelo_cal_v2_opt - s.prob_modelo_cal_v2_opt)),4) AS mae_opt_x10
FROM disc_model_owner.b46029_v2n_escopt_202609 o
LEFT JOIN d_perm_aws.scr_admbankbpe_rsk_cal_202501_202608 s ON s.tip_doc=o.tip_doc AND s.key_value=o.key_value AND s.p_codmes=CAST(o.p_codmes AS INT)
GROUP BY o.p_codmes ORDER BY o.p_codmes
