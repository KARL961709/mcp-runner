-- ============================================================================
-- V5. PLIN - EL PUENTE CIF_KEY CONTRA NUESTRAS LLAVES
--   scan: t_agg_retail_user_trx_plin U t_mst_ctaibk_rsk U ds_adm_vcnbank_tc_cal, 202412
--   ancla: PLIN esta indexado por cif_key y nosotros por tip_doc mas key_value. El
--          puente es t_mst_ctaibk_rsk. Si el puente cubre poco, PLIN no sirve como
--          driver por mas que la fuente exista. Tambien se mide si el puente es 1 a 1
-- ============================================================================
SELECT medida, valor, n
FROM (
    SELECT 'A. po en 202412'                                    AS medida,
           'personas'                                           AS valor,
           count(DISTINCT id_value)                             AS n
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal WHERE codmes_mrm = '202412'
    UNION ALL
    SELECT 'B. po con puente a cod_cuc', 'personas', count(DISTINCT c.id_value)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
    INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
            ON b.key_value = c.id_value AND CAST(b.tip_doc AS VARCHAR) = c.tip_doc
    WHERE c.codmes_mrm = '202412'
    UNION ALL
    SELECT 'C. po con fila en plin 202412', 'personas', count(DISTINCT c.id_value)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
    INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
            ON b.key_value = c.id_value AND CAST(b.tip_doc AS VARCHAR) = c.tip_doc
    INNER JOIN (SELECT DISTINCT cif_key FROM e_perm_aws.t_agg_retail_user_trx_plin
                WHERE p_codmes = '202412') p
            ON CAST(p.cif_key AS VARCHAR) = CAST(b.cod_cuc AS VARCHAR)
    WHERE c.codmes_mrm = '202412'
    UNION ALL
    SELECT 'D. llaves con mas de un cod_cuc', 'llaves', count(*)
    FROM (SELECT key_value, tip_doc FROM e_perm_aws.t_mst_ctaibk_rsk
          GROUP BY key_value, tip_doc HAVING count(DISTINCT cod_cuc) > 1) d
) z
ORDER BY medida
