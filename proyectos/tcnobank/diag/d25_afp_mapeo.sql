-- ============================================================================
-- D25. CUANTO PIERDE EL MAPEO DE RETIROS AFP
--   scan: disc_model_owner.eg_afp U e_perm_aws.t_mst_ctaibk_rsk
--   ancla: el LEFT JOIN del create original proyecta b.key_value, asi que los retiros
--          que no encuentran CUC entran como NULL y nunca excluyen a nadie. Un mapeo
--          al 60 por ciento deja la exclusion haciendo el 60 por ciento del trabajo y
--          se ve igual de limpio. Tambien se mide el formato de los dos tipo_documento
-- ============================================================================
SELECT medida, valor, n
FROM (
    SELECT 'A. eg_afp filas'                           AS medida, 'total' AS valor, count(*) AS n
    FROM disc_model_owner.eg_afp
    UNION ALL
    SELECT 'B. eg_afp con cu no nulo', 'total', count(*)
    FROM disc_model_owner.eg_afp WHERE cu IS NOT NULL
    UNION ALL
    SELECT 'C. eg_afp personas distintas', 'total', count(DISTINCT cu)
    FROM disc_model_owner.eg_afp WHERE cu IS NOT NULL
    UNION ALL
    SELECT 'D. eg_afp tipo_documento', CAST(tipo_documento AS VARCHAR), count(*)
    FROM disc_model_owner.eg_afp GROUP BY CAST(tipo_documento AS VARCHAR)
    UNION ALL
    SELECT 'E. ctaibk tip_doc', CAST(tip_doc AS VARCHAR), count(*)
    FROM e_perm_aws.t_mst_ctaibk_rsk GROUP BY CAST(tip_doc AS VARCHAR)
    UNION ALL
    SELECT 'F. mapea por cu solo', 'match', count(DISTINCT a.cu)
    FROM disc_model_owner.eg_afp a
    INNER JOIN (SELECT DISTINCT cod_cuc FROM e_perm_aws.t_mst_ctaibk_rsk) b
            ON CAST(a.cu AS VARCHAR) = CAST(b.cod_cuc AS VARCHAR)
    WHERE a.cu IS NOT NULL
    UNION ALL
    SELECT 'G. mapea por cu mas tipo_documento', 'match', count(DISTINCT a.cu)
    FROM disc_model_owner.eg_afp a
    INNER JOIN (SELECT DISTINCT cod_cuc, tip_doc FROM e_perm_aws.t_mst_ctaibk_rsk) b
            ON CAST(a.cu AS VARCHAR) = CAST(b.cod_cuc AS VARCHAR)
           AND CAST(a.tipo_documento AS VARCHAR) = CAST(b.tip_doc AS VARCHAR)
    WHERE a.cu IS NOT NULL
    UNION ALL
    SELECT 'H. de los que mapean, estan en la po', 'match', count(DISTINCT a.cu)
    FROM disc_model_owner.eg_afp a
    INNER JOIN (SELECT DISTINCT cod_cuc, key_value, tip_doc FROM e_perm_aws.t_mst_ctaibk_rsk) b
            ON CAST(a.cu AS VARCHAR) = CAST(b.cod_cuc AS VARCHAR)
    INNER JOIN (SELECT DISTINCT tip_doc, id_value FROM disc_model_owner.ds_adm_vcnbank_tc_cal) c
            ON c.id_value = b.key_value AND c.tip_doc = CAST(b.tip_doc AS VARCHAR)
    WHERE a.cu IS NOT NULL
) z
ORDER BY medida, n DESC
LIMIT 40
