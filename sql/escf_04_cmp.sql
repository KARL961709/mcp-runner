-- escf_04_cmp.sql | confirma CERO diferencia del entregable vs la ENVIADA (d_perm_aws) en el traslape 202501-202608 (esc opt + base). mae/maxdif en ppm, deben ser 0 (copiado tal cual). Agregado.
SELECT o.p_codmes, COUNT(*) AS n,
  ROUND(1e6*AVG(ABS(o.prob_modelo_cal_v2_opt - s.prob_modelo_cal_v2_opt)),3) AS mae_opt_ppm,
  ROUND(1e6*MAX(ABS(o.prob_modelo_cal_v2_opt - s.prob_modelo_cal_v2_opt)),3) AS maxdif_opt_ppm,
  SUM(CASE WHEN o.prob_modelo_cal_v2_opt <> s.prob_modelo_cal_v2_opt THEN 1 ELSE 0 END) AS n_dif_opt,
  SUM(CASE WHEN o.prob_modelo_cal_v2 <> s.prob_modelo_cal_v2 THEN 1 ELSE 0 END) AS n_dif_v2,
  SUM(CASE WHEN o.puntuacion_cal_v2_opt <> s.puntuacion_cal_v2_opt THEN 1 ELSE 0 END) AS n_dif_punt
FROM disc_model_owner.scr_admbankbpe_rsk_cal_202501_202609 o
JOIN d_perm_aws.scr_admbankbpe_rsk_cal_202501_202608 s ON s.tip_doc=o.tip_doc AND s.key_value=o.key_value AND s.p_codmes=o.p_codmes
WHERE o.p_codmes <= 202608
GROUP BY o.p_codmes ORDER BY o.p_codmes
