-- cmp_escopt_diff.sql | COMPARA nueva vs ENVIADA en 202607/202608. base: prob_modelo_cal vs prob_modelo_cal_v2 | esc opt: prob_modelo_esc_opt vs prob_modelo_cal_v2_opt. Join tip_doc+key_value+p_codmes. mae_x10 ~ 0 = cuadran. Agregado.
SELECT o.p_codmes,
  COUNT(*) AS n_match,
  ROUND(100*AVG(o.prob_modelo_cal),4) AS pd_base_new,
  ROUND(100*AVG(s.prob_modelo_cal_v2),4) AS pd_base_env,
  ROUND(1000*AVG(ABS(o.prob_modelo_cal - s.prob_modelo_cal_v2)),4) AS mae_base_x10,
  ROUND(100*AVG(o.prob_modelo_esc_opt),4) AS pd_opt_new,
  ROUND(100*AVG(s.prob_modelo_cal_v2_opt),4) AS pd_opt_env,
  ROUND(1000*AVG(ABS(o.prob_modelo_esc_opt - s.prob_modelo_cal_v2_opt)),4) AS mae_opt_x10,
  ROUND(1000*MAX(ABS(o.prob_modelo_esc_opt - s.prob_modelo_cal_v2_opt)),4) AS maxdif_opt_x10,
  SUM(CASE WHEN ABS(o.prob_modelo_esc_opt - s.prob_modelo_cal_v2_opt) > 1e-6 THEN 1 ELSE 0 END) AS n_difieren
FROM disc_model_owner.scr_admbankbpe_calibrado_202609_escopt o
JOIN d_perm_aws.scr_admbankbpe_rsk_cal_202501_202608 s ON s.tip_doc=o.tip_doc AND s.key_value=o.key_value AND s.p_codmes=CAST(o.p_codmes AS INT)
WHERE o.p_codmes IN ('202607','202608')
GROUP BY o.p_codmes ORDER BY o.p_codmes
