-- ============================================================================
-- i04. DISTRIBUCION flg_clean {1,0,99} x sub_producto x flg_ibk. READ-ONLY.
--   Tamanos de clean / dirty / scope-out para decidir el fit por scope.
-- ============================================================================
SELECT
  flg_ibk,
  sub_producto,
  flg_clean,
  count(*)                                                 AS n,
  sum(CASE WHEN target_12m IS NOT NULL THEN 1 ELSE 0 END)  AS n_maduro,
  sum(CASE WHEN flg_pd_raw = 1 THEN 1 ELSE 0 END)          AS n_score
FROM disc_model_owner.ds_adm_pp_cdpp_cal
GROUP BY flg_ibk, sub_producto, flg_clean
ORDER BY flg_ibk, sub_producto, flg_clean
