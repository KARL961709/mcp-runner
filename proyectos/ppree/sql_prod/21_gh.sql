-- ============================================================================
-- 21. GARANTIA HIPOTECARIA en t0
--   scope [ENR#L188]: prod = 06 Cred efectivo AND subprod = Cre.Efec.GH
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_21_gh AS
SELECT
  CAST(codmes AS VARCHAR)                          AS codmes,
  CAST(key_value AS VARCHAR)                       AS id_value,
  CAST(tip_doc AS VARCHAR)                         AS tip_doc,
  MAX(CASE WHEN cuc IS NOT NULL THEN 1 ELSE 0 END) AS flg_gtia_hip
FROM e_perm_aws.t_rsk_bkp_cierre_mensual
WHERE CAST(codmes AS INT) BETWEEN 201901 AND 202606
  AND prod = '06 Cred efectivo' AND subprod = 'Cre.Efec.GH'
GROUP BY 1, 2, 3
