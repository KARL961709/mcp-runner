-- v2n_12_diagdiff.sql | por que difiere 202608: distribucion de |diff v2| por mes x flg_clean. fhat uniforme -> todos chico (d_casi0 alto, d_grande~0), flg flip -> pocos con d_grande. 202607 baseline. Agregado.
SELECT sc.p_codmes, sc.flg_clean,
  COUNT(*) AS n,
  SUM(CASE WHEN ABS(sc.prob_modelo_cal_v2 - s.prob_modelo_cal_v2) < 1e-4 THEN 1 ELSE 0 END) AS d_casi0,
  SUM(CASE WHEN ABS(sc.prob_modelo_cal_v2 - s.prob_modelo_cal_v2) >= 1e-4 AND ABS(sc.prob_modelo_cal_v2 - s.prob_modelo_cal_v2) < 1e-2 THEN 1 ELSE 0 END) AS d_chico,
  SUM(CASE WHEN ABS(sc.prob_modelo_cal_v2 - s.prob_modelo_cal_v2) >= 1e-2 THEN 1 ELSE 0 END) AS d_grande,
  ROUND(1000*AVG(ABS(sc.prob_modelo_cal_v2 - s.prob_modelo_cal_v2)),4) AS mae_x10,
  ROUND(1000*MAX(ABS(sc.prob_modelo_cal_v2 - s.prob_modelo_cal_v2)),2) AS maxdif_x10
FROM disc_model_owner.b46029_v2n_scoring_202609 sc
JOIN d_perm_aws.scr_admbankbpe_rsk_cal_202501_202608 s ON s.tip_doc=sc.tip_doc AND s.key_value=sc.key_value AND s.p_codmes=CAST(sc.p_codmes AS INT)
WHERE sc.p_codmes IN ('202607','202608')
GROUP BY sc.p_codmes, sc.flg_clean ORDER BY sc.p_codmes, sc.flg_clean
