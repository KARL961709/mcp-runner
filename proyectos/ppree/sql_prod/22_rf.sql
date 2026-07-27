-- ============================================================================
-- 22. REFINANCIADOS PP en t0
--   scope [ENR#L180-181]: prod 08% AND subprod 06% AND aplicativo HPC
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_22_rf AS
SELECT
  CAST(codmes AS VARCHAR)                          AS codmes,
  CAST(key_value AS VARCHAR)                       AS id_value,
  CAST(tip_doc AS VARCHAR)                         AS tip_doc,
  MAX(CASE WHEN cuc IS NOT NULL THEN 1 ELSE 0 END) AS flg_refi
FROM e_perm_aws.t_rsk_bkp_cierre_mensual
WHERE CAST(codmes AS INT) BETWEEN 201901 AND 202606
  AND prod LIKE '08%' AND subprod LIKE '06%' AND aplicativo = 'HPC'
GROUP BY 1, 2, 3
