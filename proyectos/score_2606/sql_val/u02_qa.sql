-- u02 full QA por codmes: grano, PD en [0,1] y puntuacion 0-1000 por modelo, medias, 0 nulls en los 4.
SELECT codmes,
  COUNT(*) AS n,
  COUNT(DISTINCT cod_tip_doc || '|' || key_value) AS n_dist,
  ROUND(MIN(ft_macro_tcbnk), 6) AS ft_tc_ec,
  ROUND(MIN(ft_macro_ppfacil), 6) AS ft_pp,
  ROUND(AVG(prob_modelo_cal_ppfacil), 4) AS pd_ppf,
  ROUND(AVG(prob_modelo_cal_ppcd), 4)    AS pd_ppcd,
  ROUND(AVG(prob_modelo_cal_ec), 4)      AS pd_ec,
  ROUND(AVG(prob_modelo_cal_tcbnk), 4)   AS pd_tc,
  ROUND(MIN(prob_modelo_cal_ec), 4) AS min_pd_ec, ROUND(MAX(prob_modelo_cal_ec), 4) AS max_pd_ec,
  MIN(puntuacion_modelo_cal_tcbnk) AS min_punt_tc, MAX(puntuacion_modelo_cal_tcbnk) AS max_punt_tc,
  SUM(CASE WHEN prob_modelo_cal_ppfacil IS NULL THEN 1 ELSE 0 END) AS ppf_null,
  SUM(CASE WHEN prob_modelo_cal_ppcd IS NULL THEN 1 ELSE 0 END) AS ppcd_null,
  SUM(CASE WHEN prob_modelo_cal_ec IS NULL THEN 1 ELSE 0 END) AS ec_null,
  SUM(CASE WHEN prob_modelo_cal_tcbnk IS NULL THEN 1 ELSE 0 END) AS tc_null
FROM disc_model_owner.scr_vcadmbnk_final_hist_rsk_cal_2606_2608
GROUP BY codmes
ORDER BY codmes
