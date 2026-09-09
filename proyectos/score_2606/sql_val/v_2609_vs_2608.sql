-- v_2609_vs_2608. Sanidad distribucional: 202609 (fuente v3) vs 202608 (fuente vcadmbnk, tabla validada).
--   TTC quita la macro -> si la distribucion de pd_raw de v3 ~ vcadmbnk, la TTC promedio debe casar mes a mes.
--   PIT 202609 algo mayor que 202608 (ft senda 0.0333 > real 0.0304 en TC). Complementa el recon por-persona.
SELECT '202608' AS codmes, COUNT(*) AS n,
  ROUND(AVG(prob_modelo_cal_tcbnk), 4) AS pit_tc, ROUND(AVG(prob_modelo_ttc_cal_tcbnk), 4) AS ttc_tc,
  ROUND(AVG(prob_modelo_cal_ec), 4) AS pit_ec, ROUND(AVG(prob_modelo_ttc_cal_ec), 4) AS ttc_ec,
  ROUND(AVG(prob_modelo_cal_ppfacil), 4) AS pit_ppf, ROUND(AVG(prob_modelo_ttc_cal_ppfacil), 4) AS ttc_ppf,
  ROUND(AVG(pd_raw), 5) AS pd_raw_avg
FROM disc_model_owner.scr_vcadmbnk_final_rsk_cal_2606_2608
WHERE codmes = '202608'
GROUP BY 1
UNION ALL
SELECT '202609' AS codmes, COUNT(*) AS n,
  ROUND(AVG(prob_modelo_cal_tcbnk), 4) AS pit_tc, ROUND(AVG(prob_modelo_ttc_cal_tcbnk), 4) AS ttc_tc,
  ROUND(AVG(prob_modelo_cal_ec), 4) AS pit_ec, ROUND(AVG(prob_modelo_ttc_cal_ec), 4) AS ttc_ec,
  ROUND(AVG(prob_modelo_cal_ppfacil), 4) AS pit_ppf, ROUND(AVG(prob_modelo_ttc_cal_ppfacil), 4) AS ttc_ppf,
  ROUND(AVG(pd_raw), 5) AS pd_raw_avg
FROM disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609
WHERE codmes = '202609'
GROUP BY 1
ORDER BY codmes
