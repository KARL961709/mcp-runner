-- ============================================================================
-- i08. SERIE MACRO: RD12 mensual SS.FF (5 entidades JUNTO) vs IBK, clean vs
--   clean+dirty. Ventana amplia 201901+. Insumo de la seleccion macro (junto).
--   clean+dirty = flg_clean <> 99, maduro = target_12m no nulo. READ-ONLY.
-- ============================================================================
SELECT codmes,
  sum(CASE WHEN flg_clean <> 99 THEN 1 ELSE 0 END)                                                     AS n_ssff_cd,
  sum(CASE WHEN flg_ibk = 1 AND flg_clean <> 99 THEN 1 ELSE 0 END)                                     AS n_ibk_cd,
  round(100.0 * avg(CASE WHEN flg_clean <> 99 THEN CAST(target_12m AS DOUBLE) END), 4)                 AS rd12_ssff_cd,
  round(100.0 * avg(CASE WHEN flg_clean = 1 THEN CAST(target_12m AS DOUBLE) END), 4)                   AS rd12_ssff_clean,
  round(100.0 * avg(CASE WHEN flg_ibk = 1 AND flg_clean <> 99 THEN CAST(target_12m AS DOUBLE) END), 4) AS rd12_ibk_cd,
  round(100.0 * avg(CASE WHEN flg_ibk = 1 AND flg_clean = 1 THEN CAST(target_12m AS DOUBLE) END), 4)   AS rd12_ibk_clean
FROM disc_model_owner.ds_adm_pp_cdpp_cal
WHERE target_12m IS NOT NULL
GROUP BY codmes
ORDER BY codmes
