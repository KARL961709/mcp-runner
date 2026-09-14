-- c01. Cobertura PP Facil IBK clean maduras en altas_adm_pp_cdpp_cal: confirma existencia, volumen y RD12 por codmes.
--   n_ppf_ibk_clean_mat = poblacion para los cortes. rd12 debe rondar el ~7 pct del libro PP Facil.
SELECT CAST(codmes AS varchar) AS codmes,
  COUNT(*) AS n_ppf,
  SUM(CASE WHEN flg_ibk = 1 AND flg_clean = 1 AND target_12m IS NOT NULL AND puntuacion_modelo_cal_ppfacil IS NOT NULL THEN 1 ELSE 0 END) AS n_ppf_ibk_clean_mat,
  ROUND(AVG(CASE WHEN flg_ibk = 1 AND flg_clean = 1 AND target_12m IS NOT NULL THEN CAST(target_12m AS double) END), 4) AS rd12_ppf_ibk_clean
FROM disc_model_owner.altas_adm_pp_cdpp_cal
WHERE sub_producto = 'PP_FACIL'
GROUP BY CAST(codmes AS varchar)
ORDER BY codmes
