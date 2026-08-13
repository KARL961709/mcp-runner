-- ============================================================================
-- V5. PLIN - EL PUENTE CIF_KEY CONTRA COD_CUC, CON Y SIN RELLENO DE CEROS
--   scan: t_agg_retail_user_trx_plin U t_mst_ctaibk_rsk U ds_adm_vcnbank_tc_cal, 202412
--   ancla: R8. El monitoreo de altas IBK normaliza cif_key rellenando con ceros a la
--          izquierda hasta 10 antes de tratarlo como cod_cuc. Unir en crudo pierde
--          todo cif_key mas corto que 10 sin dar error, y la lectura seria que el
--          puente no cubre. Se miden los dos largos y las tres variantes de join
-- ============================================================================
SELECT medida, valor, n
FROM (
    SELECT 'A. plin largo de cif_key'                           AS medida,
           CAST(length(CAST(cif_key AS VARCHAR)) AS VARCHAR)    AS valor,
           count(DISTINCT cif_key)                              AS n
    FROM e_perm_aws.t_agg_retail_user_trx_plin
    WHERE p_codmes = '202412'
    GROUP BY length(CAST(cif_key AS VARCHAR))
    UNION ALL
    SELECT 'B. ctaibk largo de cod_cuc',
           CAST(length(CAST(cod_cuc AS VARCHAR)) AS VARCHAR),
           count(DISTINCT cod_cuc)
    FROM e_perm_aws.t_mst_ctaibk_rsk
    GROUP BY length(CAST(cod_cuc AS VARCHAR))
    UNION ALL
    SELECT 'C. po en 202412', 'personas', count(DISTINCT id_value)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal WHERE codmes_mrm = '202412'
    UNION ALL
    SELECT 'D. po con puente a cod_cuc', 'personas', count(DISTINCT c.id_value)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
    INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
            ON b.key_value = c.id_value AND CAST(b.tip_doc AS VARCHAR) = c.tip_doc
    WHERE c.codmes_mrm = '202412'
    UNION ALL
    SELECT 'E. plin unido EN CRUDO', 'personas', count(DISTINCT c.id_value)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
    INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
            ON b.key_value = c.id_value AND CAST(b.tip_doc AS VARCHAR) = c.tip_doc
    INNER JOIN (SELECT DISTINCT CAST(cif_key AS VARCHAR) AS cif
                FROM e_perm_aws.t_agg_retail_user_trx_plin WHERE p_codmes = '202412') p
            ON p.cif = CAST(b.cod_cuc AS VARCHAR)
    WHERE c.codmes_mrm = '202412'
    UNION ALL
    SELECT 'F. plin unido con LPAD 10', 'personas', count(DISTINCT c.id_value)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
    INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
            ON b.key_value = c.id_value AND CAST(b.tip_doc AS VARCHAR) = c.tip_doc
    INNER JOIN (SELECT DISTINCT lpad(CAST(cif_key AS VARCHAR), 10, '0') AS cif
                FROM e_perm_aws.t_agg_retail_user_trx_plin WHERE p_codmes = '202412') p
            ON p.cif = CAST(b.cod_cuc AS VARCHAR)
    WHERE c.codmes_mrm = '202412'
    UNION ALL
    SELECT 'G. plin unido con LPAD 10 en AMBOS', 'personas', count(DISTINCT c.id_value)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
    INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
            ON b.key_value = c.id_value AND CAST(b.tip_doc AS VARCHAR) = c.tip_doc
    INNER JOIN (SELECT DISTINCT lpad(CAST(cif_key AS VARCHAR), 10, '0') AS cif
                FROM e_perm_aws.t_agg_retail_user_trx_plin WHERE p_codmes = '202412') p
            ON p.cif = lpad(CAST(b.cod_cuc AS VARCHAR), 10, '0')
    WHERE c.codmes_mrm = '202412'
    UNION ALL
    SELECT 'H. llaves con mas de un cod_cuc', 'llaves', count(*)
    FROM (SELECT key_value, tip_doc FROM e_perm_aws.t_mst_ctaibk_rsk
          GROUP BY key_value, tip_doc HAVING count(DISTINCT cod_cuc) > 1) d
) z
ORDER BY medida, n DESC
LIMIT 40
