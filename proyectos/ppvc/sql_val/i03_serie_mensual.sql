-- ============================================================================
-- i03. SERIE MENSUAL: poblacion, clean/dirty/scope, cobertura score/madurez, RD12.
--   Insumo del escalon de regimen y de la ventana. IBK para la RD de calib.
--   maduro = target_12m no nulo. READ-ONLY, agregado por codmes.
-- ============================================================================
SELECT codmes,
  count(*)                                                        AS n,
  sum(CASE WHEN flg_clean = 1  THEN 1 ELSE 0 END)                 AS n_clean,
  sum(CASE WHEN flg_clean = 0  THEN 1 ELSE 0 END)                 AS n_dirty,
  sum(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END)                 AS n_scope,
  sum(CASE WHEN flg_pd_raw = 1 THEN 1 ELSE 0 END)                 AS n_score,
  sum(CASE WHEN flg_ibk = 1    THEN 1 ELSE 0 END)                 AS n_ibk,
  sum(CASE WHEN target_12m IS NOT NULL THEN 1 ELSE 0 END)         AS n_maduro,
  round(100.0 * avg(CASE WHEN flg_ibk = 1 AND flg_clean = 1 THEN CAST(target_12m AS DOUBLE) END), 4) AS rd12_ibk_clean,
  round(100.0 * avg(CASE WHEN flg_ibk = 1 AND flg_clean = 0 THEN CAST(target_12m AS DOUBLE) END), 4) AS rd12_ibk_dirty,
  round(avg(CASE WHEN flg_ibk = 1 AND flg_clean = 1 THEN pd_raw END), 6) AS pdraw_ibk_clean
FROM disc_model_owner.ds_adm_pp_cdpp_cal
GROUP BY codmes
ORDER BY codmes
