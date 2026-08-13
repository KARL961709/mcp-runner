-- ============================================================================
-- V7. PLIN - CIF_KEY ES UN HASH DE 64, NO UN CUC
--   scan: t_agg_retail_user_trx_plin U t_mst_ctaibk_rsk U ds_adm_vcnbank_tc_cal, 202412
--   ancla: v5 midio cif_key largo 64 y cod_cuc largo 10, y las tres variantes de join
--          dieron cero. El cif_key del monitoreo de altas es numerico y se rellena a
--          10, pero el de PLIN es otra cosa con el mismo nombre. 64 es el formato de
--          nuestro id_value, asi que se prueba el join directo y el que pasa por el
--          key_value del puente, que tambien deberia ser 64
-- ============================================================================
SELECT medida, valor, n
FROM (
    SELECT 'A. ctaibk largo de key_value'                       AS medida,
           CAST(length(CAST(key_value AS VARCHAR)) AS VARCHAR)  AS valor,
           count(DISTINCT key_value)                            AS n
    FROM e_perm_aws.t_mst_ctaibk_rsk
    GROUP BY length(CAST(key_value AS VARCHAR))
    UNION ALL
    SELECT 'B. po en 202412', 'personas', count(DISTINCT id_value)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal WHERE codmes_mrm = '202412'
    UNION ALL
    SELECT 'C. plin unido DIRECTO a id_value', 'personas', count(DISTINCT c.id_value)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
    INNER JOIN (SELECT DISTINCT CAST(cif_key AS VARCHAR) AS cif
                FROM e_perm_aws.t_agg_retail_user_trx_plin WHERE p_codmes = '202412') p
            ON p.cif = c.id_value
    WHERE c.codmes_mrm = '202412'
    UNION ALL
    SELECT 'D. plin unido via key_value del puente', 'personas', count(DISTINCT c.id_value)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
    INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
            ON b.key_value = c.id_value AND CAST(b.tip_doc AS VARCHAR) = c.tip_doc
    INNER JOIN (SELECT DISTINCT CAST(cif_key AS VARCHAR) AS cif
                FROM e_perm_aws.t_agg_retail_user_trx_plin WHERE p_codmes = '202412') p
            ON p.cif = CAST(b.key_value AS VARCHAR)
    WHERE c.codmes_mrm = '202412'
    UNION ALL
    SELECT 'E. plin distintos en 202412', 'cif_key', count(DISTINCT cif_key)
    FROM e_perm_aws.t_agg_retail_user_trx_plin WHERE p_codmes = '202412'
    UNION ALL
    SELECT 'F. de esos, cuantos estan en la po de ese mes', 'cif_key',
           count(DISTINCT p.cif)
    FROM (SELECT DISTINCT CAST(cif_key AS VARCHAR) AS cif
          FROM e_perm_aws.t_agg_retail_user_trx_plin WHERE p_codmes = '202412') p
    INNER JOIN (SELECT DISTINCT id_value FROM disc_model_owner.ds_adm_vcnbank_tc_cal
                WHERE codmes_mrm = '202412') c
            ON c.id_value = p.cif
) z
ORDER BY medida, n DESC
LIMIT 30
