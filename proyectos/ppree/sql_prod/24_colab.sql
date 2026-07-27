-- ============================================================================
-- 24. COLABORADORES IBK [ENR#L194]
--   fuente medida 201903-202401 (H15) -> valida en t0 = [201905, 202403] (H51)
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_24_colab AS
SELECT DISTINCT
  CAST(periodo_gdh AS VARCHAR) AS codmes,
  CAST(key_value AS VARCHAR)   AS id_value,
  CAST(tipdoc AS VARCHAR)      AS tip_doc,
  1                            AS flg_colab
FROM e_perm_aws.t_colaboradores_gdh_rsk
WHERE empresa = 'INTERBANK'
  AND LENGTH(CAST(key_value AS VARCHAR)) = 64
