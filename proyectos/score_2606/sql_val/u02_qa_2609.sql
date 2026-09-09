-- u02 QA 2609: tabla final scr_vcadmbnk_final_rsk_cal_2609 (PIT + TTC). ft>0 en 202609 -> TTC < PIT. 0 nulls.
--   ft_macro debe ser la senda (tc/ec=0.033297, pp=0.100265). puntuacion 0-1000.
SELECT codmes, COUNT(*) AS n,
  ROUND(AVG(prob_modelo_cal_tcbnk), 4) AS pit_tc, ROUND(AVG(prob_modelo_ttc_cal_tcbnk), 4) AS ttc_tc,
  ROUND(AVG(prob_modelo_cal_ec), 4) AS pit_ec, ROUND(AVG(prob_modelo_ttc_cal_ec), 4) AS ttc_ec,
  ROUND(AVG(prob_modelo_cal_ppfacil), 4) AS pit_ppf, ROUND(AVG(prob_modelo_ttc_cal_ppfacil), 4) AS ttc_ppf,
  ROUND(AVG(prob_modelo_cal_ppcd), 4) AS pit_ppcd, ROUND(AVG(prob_modelo_ttc_cal_ppcd), 4) AS ttc_ppcd,
  ROUND(AVG(ft_macro_tcbnk), 6) AS ft_tc, ROUND(AVG(ft_macro_ppfacil), 6) AS ft_pp,
  SUM(CASE WHEN prob_modelo_ttc_cal_tcbnk > prob_modelo_cal_tcbnk THEN 1 ELSE 0 END) AS n_ttc_gt_pit_tc,
  SUM(CASE WHEN prob_modelo_cal_tcbnk IS NULL OR prob_modelo_cal_ec IS NULL OR prob_modelo_cal_ppfacil IS NULL OR prob_modelo_cal_ppcd IS NULL THEN 1 ELSE 0 END) AS pit_null,
  SUM(CASE WHEN puntuacion_modelo_cal_tcbnk < 0 OR puntuacion_modelo_cal_tcbnk > 1000 THEN 1 ELSE 0 END) AS punt_oob
FROM disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609
GROUP BY codmes
ORDER BY codmes
