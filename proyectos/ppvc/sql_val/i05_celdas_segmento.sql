-- ============================================================================
-- i05. CELDAS de calibracion: sub_producto x tipo_ingreso x nodo, IBK,
--   scoreado+maduro, clean y dirty. n y n_malos por celda -> viabilidad del
--   grano (suficientes malos para el calibrador). READ-ONLY.
-- ============================================================================
SELECT
  sub_producto,
  tipo_ingreso,
  nodo,
  flg_clean,
  count(*)                                            AS n,
  sum(CAST(target_12m AS INTEGER))                    AS n_malos,
  round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)   AS rd12
FROM disc_model_owner.ds_adm_pp_cdpp_cal
WHERE flg_ibk = 1
  AND flg_pd_raw = 1
  AND target_12m IS NOT NULL
  AND flg_clean IN (0, 1)
GROUP BY sub_producto, tipo_ingreso, nodo, flg_clean
ORDER BY sub_producto, tipo_ingreso, nodo, flg_clean
