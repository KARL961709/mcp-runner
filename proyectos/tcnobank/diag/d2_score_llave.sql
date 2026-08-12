-- ============================================================================
-- D2. POR QUE NO CRUZA EL SCORE - FORMATO Y DESCOMPOSICION DEL MATCH
-- ============================================================================
SELECT medida, valor, n
FROM (
    SELECT 'A. scr.cod_tip_doc' AS medida, CAST(length(cod_tip_doc) AS VARCHAR) AS valor, count(*) AS n
    FROM e_perm_aws.scr_vcnbank_rsk WHERE p_codmes = '202412' GROUP BY length(cod_tip_doc)
    UNION ALL
    SELECT 'B. scr.key_value', CAST(length(key_value) AS VARCHAR), count(*)
    FROM e_perm_aws.scr_vcnbank_rsk WHERE p_codmes = '202412' GROUP BY length(key_value)
    UNION ALL
    SELECT 'C. po.tip_doc', CAST(length(tip_doc) AS VARCHAR), count(*)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal WHERE codmes_mrm = '202412' GROUP BY length(tip_doc)
    UNION ALL
    SELECT 'D. po.id_value', CAST(length(id_value) AS VARCHAR), count(*)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal WHERE codmes_mrm = '202412' GROUP BY length(id_value)
    UNION ALL
    SELECT 'E. scr.cod_tip_doc valores', cod_tip_doc, count(*)
    FROM e_perm_aws.scr_vcnbank_rsk WHERE p_codmes = '202412' GROUP BY cod_tip_doc
    UNION ALL
    SELECT 'F. po.tip_doc valores', tip_doc, count(*)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal WHERE codmes_mrm = '202412' GROUP BY tip_doc
) z
ORDER BY medida, n DESC
LIMIT 60
