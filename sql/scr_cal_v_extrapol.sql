-- scr_cal_v_extrapol | por tramo de pd_raw: promedio pd_raw vs prob_modelo_cal vs pd_opt_v2 (para ver DONDE divergen -> la cola alta por el clip de la isotonica). Agregado.
SELECT
  CASE WHEN TRY_CAST(probabilidad AS DOUBLE) < 0.05 THEN '1_<5%'
       WHEN TRY_CAST(probabilidad AS DOUBLE) < 0.10 THEN '2_5-10%'
       WHEN TRY_CAST(probabilidad AS DOUBLE) < 0.20 THEN '3_10-20%'
       WHEN TRY_CAST(probabilidad AS DOUBLE) < 0.40 THEN '4_20-40%'
       ELSE '5_>40%' END AS tramo_pdraw,
  COUNT(*) AS n,
  ROUND(100*AVG(TRY_CAST(probabilidad AS DOUBLE)),2) AS pd_raw,
  ROUND(100*AVG(prob_modelo_cal),2) AS pd_cal,
  ROUND(100*AVG(pd_opt_v2),2) AS pd_v2,
  ROUND(100*MAX(prob_modelo_cal),2) AS max_pd_cal
FROM disc_model_owner.b46029_scr_admbankbpe_cal_202608
GROUP BY 1 ORDER BY 1
