-- ============================================================================
-- v20. FRONTERA de pd_raw y de target_12m por codmes, contando filas
--   Cobertura real del perimetro reenganche desde 202504. No usa min/max:
--   una particion declarada puede estar vacia.
-- ============================================================================
SELECT
  codmes_mrm                                                              AS codmes,
  COUNT(*)                                                                AS n_scope,
  SUM(CASE WHEN pd_raw IS NOT NULL THEN 1 ELSE 0 END)                     AS n_pd,
  SUM(CASE WHEN pd_raw > 0 AND pd_raw < 1 THEN 1 ELSE 0 END)              AS n_pd_rango,
  SUM(CASE WHEN target_12m_60 IS NOT NULL THEN 1 ELSE 0 END)              AS n_t12,
  SUM(CASE WHEN falla_madurez_12 = 0 THEN 1 ELSE 0 END)                   AS n_mad12_ok,
  SUM(CASE WHEN target_06m_60 IS NOT NULL THEN 1 ELSE 0 END)              AS n_t06,
  SUM(CASE WHEN flg_clean = 1 THEN 1 ELSE 0 END)                          AS n_clean,
  SUM(CASE WHEN flg_clean = 1 AND flg_calib = 1 THEN 1 ELSE 0 END)        AS n_fit,
  SUM(CASE WHEN flg_clean = 1 AND flg_calib = 1 THEN target_12m_60 END)   AS malos_fit,
  COUNT(DISTINCT tipo_ingreso_dep)                                        AS n_seg
FROM disc_model_owner.ds_stk_ree_pp_cal
WHERE flg_scope_ree = 1
  AND codmes_mrm >= '202504'
GROUP BY codmes_mrm
ORDER BY 1
