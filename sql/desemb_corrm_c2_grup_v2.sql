-- desemb_corrm_c2_grup_v2.sql | grupos corregidos v2 sobre 202501-207 maduras (universo calib): RD vs PD final vs N. Debe realizar el apetito con los cortes optimizados. Agregado.
SELECT grupo_cal,
  COUNT(*) AS n,
  COUNT(CASE WHEN meses_madurez=12 THEN 1 END) AS n_mad,
  ROUND(100*AVG(pd_pit_final),2) AS pd_final,
  ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN target_12m END),2) AS rd12
FROM disc_model_owner.b46029_desemb_maestra_corrv2_202609
WHERE flg_cruce=1 AND flg_universo_calib=1 AND cod_mes BETWEEN 202501 AND 202507
GROUP BY grupo_cal ORDER BY grupo_cal
