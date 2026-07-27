-- ============================================================================
-- 24. COLABORADORES IBK [ENR#L194]
--   fuente medida 201903-202401 (H15) -> valida en t0 = [201905, 202403] (H51)
--   flg_colab sale de codunicocli IS NOT NULL, como el Recibido (ENR#L291) y
--   como ya hacen 21_gh y 22_rf. Una constante 1 sobre-excluye: una fila con
--   codunicocli nulo da 0 en el Recibido y daba 1 aca (F2).
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_24_colab AS
SELECT
  CAST(periodo_gdh AS VARCHAR)                              AS codmes,
  CAST(key_value AS VARCHAR)                                AS id_value,
  CAST(tipdoc AS VARCHAR)                                   AS tip_doc,
  MAX(CASE WHEN codunicocli IS NOT NULL THEN 1 ELSE 0 END)  AS flg_colab
FROM e_perm_aws.t_colaboradores_gdh_rsk
WHERE empresa = 'INTERBANK'
  AND LENGTH(CAST(key_value AS VARCHAR)) = 64
GROUP BY 1, 2, 3
