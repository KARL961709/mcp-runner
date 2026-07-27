-- ============================================================================
-- 10. POBLACION OBJETIVO
--   scan: d_perm_aws.ds_compppibk_rsk [201902,202012] U e_perm_aws.scr_compppibk_rsk [202101,202607]
--   ancla: codmes_mrm = DATE_ADD(-1 mes) sobre codmes. Nunca resta entera (O6/P1)
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_10_po AS
WITH src AS (
  SELECT CAST(codmes AS VARCHAR) AS codmes, CAST(tip_doc AS VARCHAR) AS tip_doc,
         CAST(key_value AS VARCHAR) AS key_value, 'd_perm' AS fuente
  FROM d_perm_aws.ds_compppibk_rsk
  WHERE CAST(codmes AS INT) BETWEEN 201902 AND 202012
  UNION ALL
  SELECT CAST(codmes AS VARCHAR), CAST(tip_doc AS VARCHAR),
         CAST(key_value AS VARCHAR), 'e_perm'
  FROM e_perm_aws.scr_compppibk_rsk
  WHERE CAST(codmes AS INT) BETWEEN 202101 AND 202607
)
SELECT DISTINCT
  DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(codmes, '%Y%m')), '%Y%m') AS codmes_mrm,
  codmes                                                                 AS codmes_scr,
  tip_doc,
  key_value                                                              AS id_value,
  fuente
FROM src
WHERE LENGTH(key_value) = 64
