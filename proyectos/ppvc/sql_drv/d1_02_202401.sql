-- ============================================================================
-- d1_02. INSERT trimestre 202401-202403 en drv_income_ppvc.
-- ============================================================================
INSERT INTO disc_model_owner.drv_income_ppvc
WITH rk AS (
  SELECT CAST(tip_doc AS varchar) AS tip_doc,
         SUBSTR(subject_id, 3) AS key_value,
         periodo AS codmes, fuente, sit_lab,
         ROW_NUMBER() OVER (
           PARTITION BY SUBSTR(subject_id, 3), periodo, CAST(tip_doc AS varchar)
           ORDER BY p_fecinformacion DESC) AS rn
  FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
  WHERE CAST(numcarga AS integer) = 1
    AND periodo BETWEEN '202401' AND '202403'
)
SELECT tip_doc, key_value,
  CASE WHEN sit_lab = 'DEPENDIENTE' AND fuente NOT IN ('INFERIDO', 'EXPERIAN', 'SUSALUD', 'INFERIDO_IND_MVP')
       THEN 'DEP' ELSE 'NO_DEP' END AS trf_tipo_ingreso,
  codmes
FROM rk
WHERE rn = 1