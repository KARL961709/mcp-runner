-- ============================================================================
-- 26. MESES PRESENTES EN EL CIERRE MENSUAL (scope PP HPC)
--   falla_foto_t0 es un flag de MES, no de fila (D1). Sin esta tabla, un
--   cliente sin cuenta HPC en su t0 -que es normal- quedaba marcado igual que
--   el hueco 202107, y se iba a flg_clean = 99 por un control que no le tocaba.
--   Se deriva de la fuente: si manana falta otro mes, aparece solo.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_26_meses AS
SELECT
  CAST(codmes AS VARCHAR) AS codmes,
  COUNT(*)                AS n_filas
FROM e_perm_aws.t_rsk_bkp_cierre_mensual
WHERE CAST(codmes AS INT) BETWEEN 201901 AND 202606
  AND prod LIKE '06%' AND (subprod IS NULL OR subprod <> 'Cre.Efec.GH') AND aplicativo = 'HPC'
GROUP BY 1
