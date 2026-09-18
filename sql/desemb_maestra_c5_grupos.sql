-- QA[5] DISTRIBUCION por grupo_cal (PD vs RD maduras <=2025Q1, universo calib): debe calzar el reporte
SELECT grupo_cal,
  COUNT(*) AS n_total,
  COUNT(CASE WHEN meses_madurez=12 AND cod_mes<=202503 THEN 1 END) AS n_mad,
  ROUND(100*AVG(CASE WHEN meses_madurez=12 AND cod_mes<=202503 THEN pd_pit_final END),2) AS pd,
  ROUND(100*AVG(CASE WHEN meses_madurez=12 AND cod_mes<=202503 THEN target_12m END),2) AS rd
FROM disc_model_owner.b46029_desemb_maestra_202609
WHERE flg_cruce=1 AND flg_universo_calib=1
GROUP BY grupo_cal ORDER BY grupo_cal
