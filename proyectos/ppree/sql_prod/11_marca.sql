-- ============================================================================
-- 11. MARCA REENGANCHE - perimetro (A14)
--   grano (id_value, codmes_mrm), SIN tip_doc: con el mete fan-out del puente (A17, H38)
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_11_marca AS
SELECT DISTINCT
  CAST(b.key_value AS VARCHAR)         AS id_value,
  CAST(a.codmes_desembolso AS VARCHAR) AS codmes_mrm
FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp a
INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
  ON CAST(a.cif_key AS VARCHAR) = CAST(b.cod_cuc AS VARCHAR)
WHERE a.subproducto = '1.REENGANCHE'
  AND LENGTH(CAST(b.key_value AS VARCHAR)) = 64
