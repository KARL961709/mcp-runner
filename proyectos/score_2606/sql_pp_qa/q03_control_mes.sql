-- q03 control de ejecucion por mes (rango 202401-202608). n, ft distinto por mes (debe ser 1), missing/nulls (deben ser 0), cobertura clean, PD. Read-only.
SELECT codmes,
  COUNT(*) AS n,
  COUNT(DISTINCT ft_macro_pp) AS n_ft_distinct,
  round(MAX(ft_macro_pp), 10) AS ft_pp,
  SUM(CASE WHEN prob_modelo IS NULL THEN 1 ELSE 0 END) AS n_prob_null,
  SUM(CASE WHEN prob_modelo_cal_ppfacil IS NULL THEN 1 ELSE 0 END) AS n_calfacil_null,
  SUM(CASE WHEN prob_modelo_cal_ppcd IS NULL THEN 1 ELSE 0 END) AS n_calppcd_null,
  SUM(CASE WHEN prob_modelo_ttc_ppfacil IS NULL THEN 1 ELSE 0 END) AS n_ttcfacil_null,
  SUM(CASE WHEN tipo_ingreso IS NULL THEN 1 ELSE 0 END) AS n_tipoing_null,
  SUM(CASE WHEN nodo_ppfacil IS NULL THEN 1 ELSE 0 END) AS n_nodofacil_null,
  SUM(CASE WHEN nodo_ppcd IS NULL THEN 1 ELSE 0 END) AS n_nodoppcd_null,
  SUM(flg_clean) AS n_clean,
  round(100.0 * SUM(flg_clean) / COUNT(*), 2) AS pct_clean,
  round(AVG(prob_modelo_cal_ppfacil) * 100, 3) AS pd_cal_ppfacil_pct
FROM disc_model_owner.scr_admvc_pp_cal_202401_202608
GROUP BY codmes
ORDER BY codmes
