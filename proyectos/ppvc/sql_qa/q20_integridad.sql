-- ============================================================================
-- q20. Integridad: AMBAS prob no-nulas (todo scoreado), rangos, flg_clean 0/1.
--      Todas las columnas de conteo deben dar 0.
-- ============================================================================
SELECT
  COUNT(*) AS n,
  SUM(CASE WHEN prob_modelo_cal_ppfacil IS NULL THEN 1 ELSE 0 END) AS facil_null,
  SUM(CASE WHEN prob_modelo_cal_ppcd IS NULL THEN 1 ELSE 0 END) AS cd_null,
  SUM(CASE WHEN prob_modelo_cal_ppfacil <= 0 OR prob_modelo_cal_ppfacil >= 1 THEN 1 ELSE 0 END) AS facil_fuera01,
  SUM(CASE WHEN prob_modelo_cal_ppcd <= 0 OR prob_modelo_cal_ppcd >= 1 THEN 1 ELSE 0 END) AS cd_fuera01,
  SUM(CASE WHEN puntuacion_modelo_cal_ppfacil NOT BETWEEN 0 AND 1000 THEN 1 ELSE 0 END) AS punt_facil_fuera,
  SUM(CASE WHEN puntuacion_modelo_cal_ppcd NOT BETWEEN 0 AND 1000 THEN 1 ELSE 0 END) AS punt_cd_fuera,
  SUM(CASE WHEN flg_clean IS NULL OR flg_clean NOT IN (0, 1) THEN 1 ELSE 0 END) AS flgclean_raro,
  SUM(CASE WHEN pd_raw <= 0 OR pd_raw >= 1 THEN 1 ELSE 0 END) AS pd_raw_fuera01
FROM disc_model_owner.scr_ppvc_cal
