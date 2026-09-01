-- ============================================================================
-- d1_01. CREATE drv_income_ppvc (particion codmes) - trimestre 202311-202312. Logica 03 (sit_lab).
-- ============================================================================
CREATE TABLE disc_model_owner.drv_income_ppvc
WITH (format = 'PARQUET', write_compression = 'SNAPPY', partitioned_by = ARRAY['codmes'],
      external_location = '<S3_DATOS>/drv_income/') AS
WITH rk AS (
  SELECT CAST(tip_doc AS varchar) AS tip_doc,
         SUBSTR(subject_id, 3) AS key_value,
         periodo AS codmes, fuente, sit_lab,
         ROW_NUMBER() OVER (
           PARTITION BY SUBSTR(subject_id, 3), periodo, CAST(tip_doc AS varchar)
           ORDER BY p_fecinformacion DESC) AS rn
  FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
  WHERE CAST(numcarga AS integer) = 1
    AND periodo BETWEEN '202311' AND '202312'
)
SELECT tip_doc, key_value,
  CASE WHEN sit_lab = 'DEPENDIENTE' AND fuente NOT IN ('INFERIDO', 'EXPERIAN', 'SUSALUD', 'INFERIDO_IND_MVP')
       THEN 'DEP' ELSE 'NO_DEP' END AS trf_tipo_ingreso,
  codmes
FROM rk
WHERE rn = 1