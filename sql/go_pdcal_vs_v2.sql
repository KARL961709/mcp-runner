-- go_pdcal_vs_v2 | SOLO los que ENTRAN (flg_camp=1): PD cal ultima (prob_modelo_cal DSM) vs V2 (pd_v2_esc_opt) por personeria. Promedios, diferencia (cal-v2) y % donde la DSM es MENOR que la V2.
SELECT CASE WHEN tip_doc='1' THEN 'PN' ELSE 'PJ' END AS per,
  COUNT(*) AS n,
  ROUND(100*AVG(prob_modelo_cal),3) AS pd_cal_dsm,
  ROUND(100*AVG(pd_v2_esc_opt),3) AS pd_v2,
  ROUND(100*AVG(prob_modelo_cal-pd_v2_esc_opt),3) AS dif_pp,
  ROUND(100.0*AVG(CASE WHEN prob_modelo_cal < pd_v2_esc_opt THEN 1 ELSE 0 END),1) AS pct_dsm_menor
FROM disc_model_owner.admbank_prosp_202608
WHERE flg_camp=1
GROUP BY CASE WHEN tip_doc='1' THEN 'PN' ELSE 'PJ' END
ORDER BY 1
