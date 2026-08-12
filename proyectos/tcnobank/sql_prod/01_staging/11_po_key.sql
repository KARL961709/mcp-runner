-- ============================================================================
-- 11. LLAVES - SBS_VALUE Y COD_CUC CON COBERTURA
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_11_po_key
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm']
) AS
WITH sbs AS (
    SELECT tip_doc, key_value, sbs_value FROM (
        SELECT tip_doc, key_value, sbs_value,
               row_number() OVER (PARTITION BY tip_doc, key_value
                                  ORDER BY fch_creacion DESC, sbs_value ASC) AS rn
        FROM e_perm_aws.t_mst_ctarcc_rsk) x
    WHERE x.rn = 1
),
cuc AS (
    SELECT tip_doc, key_value, cod_cuc FROM (
        SELECT tip_doc, key_value, cod_cuc,
               row_number() OVER (PARTITION BY tip_doc, key_value
                                  ORDER BY fch_pricont DESC, cod_cuc ASC) AS rn
        FROM e_perm_aws.t_mst_ctaibk_rsk) x
    WHERE x.rn = 1
)
SELECT p.tip_doc,
       p.id_value,
       p.entidad,
       p.saldo_tc_ori,
       s.sbs_value,
       c.cod_cuc,
       CAST(CASE WHEN s.sbs_value IS NULL THEN 1 ELSE 0 END AS INTEGER)                AS falla_sin_sbs,
       CAST(CASE WHEN c.cod_cuc   IS NULL THEN 1 ELSE 0 END AS INTEGER)                AS falla_sin_cuc,
       p.codmes_mrm
FROM disc_model_owner.ds_adm_vcnbank_tc_10_po p
LEFT JOIN sbs s ON s.tip_doc = p.tip_doc AND s.key_value = p.id_value
LEFT JOIN cuc c ON c.tip_doc = p.tip_doc AND c.key_value = p.id_value
