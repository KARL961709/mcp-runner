-- cmp_src_v2n.sql | confirma si el _v2 enviado = v2native (clean/dirty). Compara b46029_v2n_scoring_202607.prob_modelo_cal_v2 vs enviada.prob_modelo_cal_v2 en 202607. mae~0 = la enviada ES v2native. Agregado.
SELECT COUNT(*) AS n,
  ROUND(100*AVG(v.prob_modelo_cal_v2),4) AS pd_v2n,
  ROUND(100*AVG(s.prob_modelo_cal_v2),4) AS pd_enviada,
  ROUND(1000*AVG(ABS(v.prob_modelo_cal_v2 - s.prob_modelo_cal_v2)),4) AS mae_x10
FROM disc_model_owner.b46029_v2n_scoring_202607 v
JOIN d_perm_aws.scr_admbankbpe_rsk_cal_202501_202608 s
  ON s.tip_doc=v.tip_doc AND s.key_value=v.key_value AND s.p_codmes=CAST(v.p_codmes AS INT)
WHERE CAST(v.p_codmes AS INT)=202607
