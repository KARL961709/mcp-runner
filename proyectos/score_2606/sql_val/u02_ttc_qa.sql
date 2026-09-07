-- u02_ttc_qa. Verifica la tabla adicional scr_vcadmbnk_final_rsk_cal_2606_2608 (PIT + TTC).
--   Como ft>0 en 202606-208, la TTC (lambda=0) debe ser < la PIT en cada modelo. n_ttc_gt_pit ~0. 0 nulls.
SELECT codmes, COUNT(*) AS n,
  ROUND(AVG(prob_modelo_cal_tcbnk), 4) AS pit_tc, ROUND(AVG(prob_modelo_ttc_cal_tcbnk), 4) AS ttc_tc,
  ROUND(AVG(prob_modelo_cal_ec), 4) AS pit_ec, ROUND(AVG(prob_modelo_ttc_cal_ec), 4) AS ttc_ec,
  ROUND(AVG(prob_modelo_cal_ppfacil), 4) AS pit_ppf, ROUND(AVG(prob_modelo_ttc_cal_ppfacil), 4) AS ttc_ppf,
  ROUND(AVG(prob_modelo_cal_ppcd), 4) AS pit_ppcd, ROUND(AVG(prob_modelo_ttc_cal_ppcd), 4) AS ttc_ppcd,
  SUM(CASE WHEN prob_modelo_ttc_cal_tcbnk > prob_modelo_cal_tcbnk THEN 1 ELSE 0 END) AS n_ttc_gt_pit_tc,
  SUM(CASE WHEN prob_modelo_ttc_cal_tcbnk IS NULL OR prob_modelo_ttc_cal_ec IS NULL THEN 1 ELSE 0 END) AS ttc_null
FROM disc_model_owner.scr_vcadmbnk_final_rsk_cal_2606_2608
GROUP BY codmes
ORDER BY codmes
