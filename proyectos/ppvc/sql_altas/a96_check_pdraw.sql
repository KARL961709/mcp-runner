-- a96. Prueba de la regla: prob_modelo_cal existe SI Y SOLO SI hay pd_raw, sin importar flg_calib.
--      Para flg_calib 0 y 1: n_pdcal_f y n_pdcal_c deben ser IGUALES a n_pdraw (no restringimos por flg_calib).
SELECT flg_calib, flg_clean, COUNT(*) AS n,
  SUM(CASE WHEN pd_raw IS NOT NULL THEN 1 ELSE 0 END) AS n_pdraw,
  SUM(CASE WHEN prob_modelo_cal_ppfacil IS NOT NULL THEN 1 ELSE 0 END) AS n_pdcal_f,
  SUM(CASE WHEN prob_modelo_cal_ppcd IS NOT NULL THEN 1 ELSE 0 END) AS n_pdcal_c
FROM disc_model_owner.altas_adm_pp_cdpp_cal
GROUP BY flg_calib, flg_clean
ORDER BY flg_calib, flg_clean