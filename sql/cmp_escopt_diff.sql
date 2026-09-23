-- cmp_escopt_diff.sql | COMPARA esc opt nueva (prob_modelo_esc_opt) vs enviada (v2_esc_opt) en el traslape 202607/202608. Join por tip_doc+key_value+p_codmes. mae_x10 ~ 0 = cuadran. Agregado.
SELECT o.p_codmes,
  COUNT(*) AS n_match,
  ROUND(100*AVG(o.prob_modelo_esc_opt),4) AS pd_nuevo_pct,
  ROUND(100*AVG(TRY_CAST(s.v2_esc_opt AS DOUBLE)),4) AS pd_enviado_pct,
  ROUND(1000*AVG(ABS(o.prob_modelo_esc_opt - TRY_CAST(s.v2_esc_opt AS DOUBLE))),4) AS mae_x10,
  ROUND(1000*MAX(ABS(o.prob_modelo_esc_opt - TRY_CAST(s.v2_esc_opt AS DOUBLE))),4) AS maxdif_x10,
  SUM(CASE WHEN ABS(o.prob_modelo_esc_opt - TRY_CAST(s.v2_esc_opt AS DOUBLE)) > 1e-6 THEN 1 ELSE 0 END) AS n_difieren
FROM disc_model_owner.scr_admbankbpe_calibrado_202609_escopt o
JOIN d_perm_aws.scr_admbankbpe_rsk_cal_202501_202608 s ON s.tip_doc=o.tip_doc AND s.key_value=o.key_value AND CAST(s.p_codmes AS INT)=CAST(o.p_codmes AS INT)
WHERE o.p_codmes IN ('202607','202608')
GROUP BY o.p_codmes ORDER BY o.p_codmes
