-- QA[2] nulos en las columnas de calibracion (deben ser 0)
SELECT COUNT(*) AS n, SUM(CASE WHEN prob_modelo_cal IS NULL THEN 1 ELSE 0 END) AS prob_null,
  SUM(CASE WHEN puntuacion_cal IS NULL THEN 1 ELSE 0 END) AS punt_null,
  SUM(CASE WHEN grupos_cal IS NULL THEN 1 ELSE 0 END) AS grupo_null,
  SUM(CASE WHEN desc_cliente_cal IS NULL THEN 1 ELSE 0 END) AS desc_null
FROM disc_model_owner.b46029_scr_admbankbpe_cal_202608
