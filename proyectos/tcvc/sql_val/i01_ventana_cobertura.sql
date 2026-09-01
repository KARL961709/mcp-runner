-- i01. E1 ventana + cobertura CONTANDO FILAS (no min/max). Poblacion fit = ibk & clean & pd_raw & maduro.
SELECT codmes,
  COUNT(*) AS n,
  SUM(CASE WHEN flg_ibk = 1 THEN 1 ELSE 0 END) AS n_ibk,
  SUM(CASE WHEN flg_clean = 1 THEN 1 ELSE 0 END) AS n_clean,
  SUM(CASE WHEN flg_ibk = 1 AND flg_clean = 1 THEN 1 ELSE 0 END) AS n_ibk_clean,
  SUM(CASE WHEN pd_raw IS NOT NULL THEN 1 ELSE 0 END) AS n_pdraw,
  SUM(CASE WHEN flg_ibk = 1 AND flg_clean = 1 AND pd_raw IS NOT NULL AND target_12m IS NOT NULL THEN 1 ELSE 0 END) AS n_fit,
  ROUND(AVG(CASE WHEN flg_ibk = 1 AND flg_clean = 1 AND target_12m IS NOT NULL THEN CAST(target_12m AS double) END), 5) AS rd12_ibk_clean
FROM disc_model_owner.ds_adm_tcbank_cal
GROUP BY codmes
ORDER BY codmes