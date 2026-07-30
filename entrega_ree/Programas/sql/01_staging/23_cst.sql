-- ============================================================================
-- 23. CASTIGOS - mes truncado del timestamp ingreso_cj_fc
--   la llave sale del puente CIF(P9)
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_23_cst AS
SELECT DISTINCT
  DATE_FORMAT(a.ingreso_cj_fc, '%Y%m') AS codmes,
  CAST(c.key_value AS VARCHAR)         AS id_value,
  CAST(c.tip_doc AS VARCHAR)           AS tip_doc,
  1                                    AS flg_castigo
FROM e_perm_aws.t_sco_maestro_cl_rsk a
INNER JOIN e_perm_aws.t_mst_ctaibk_rsk c
  ON CAST(a.cod_cuc AS VARCHAR) = CAST(c.cod_cuc AS VARCHAR)
WHERE a.ingreso_cj_fc IS NOT NULL
  AND DATE_FORMAT(a.ingreso_cj_fc, '%Y%m') BETWEEN '201901' AND '202606'
  AND LENGTH(CAST(c.key_value AS VARCHAR)) = 64
