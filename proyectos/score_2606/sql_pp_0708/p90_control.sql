-- p90 control 202607-202608: n por mes, ft aplicado (1 distinto/mes), nulls (0), todo calibrado. Read-only.
SELECT codmes,
  COUNT(*) AS n,
  COUNT(DISTINCT ft_macro_pp) AS n_ft_distinct,
  round(MAX(ft_macro_pp), 10) AS ft_pp,
  SUM(CASE WHEN prob_modelo IS NULL THEN 1 ELSE 0 END) AS n_prob_null,
  SUM(CASE WHEN prob_modelo_cal_ppfacil IS NULL THEN 1 ELSE 0 END) AS n_calfacil_null,
  SUM(CASE WHEN prob_modelo_cal_ppcd IS NULL THEN 1 ELSE 0 END) AS n_calppcd_null,
  SUM(CASE WHEN prob_modelo IS NOT NULL AND prob_modelo_cal_ppfacil IS NULL THEN 1 ELSE 0 END) AS n_facil_sin_cal,
  SUM(flg_clean) AS n_clean,
  round(AVG(prob_modelo_cal_ppfacil) * 100, 3) AS pd_cal_ppfacil_pct
FROM disc_model_owner.scr_admvc_pp_cal_202607_202608
GROUP BY codmes
ORDER BY codmes
