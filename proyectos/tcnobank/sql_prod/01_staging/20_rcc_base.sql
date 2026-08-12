-- ============================================================================
-- 20. RCC EN ORIGEN - VARIANTES M0 Y M2
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_20_rcc_base
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm'],
    external_location   = '<S3_DATOS>/adm_vcnbank_tc_20_rcc_base/'
) AS
WITH po AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad,
           date_format(date_add('month', -2, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS m02
    FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
),
cli AS (
    SELECT codmes, tip_doc, key_value,
           sum(monto_cast) AS monto_cast,
           sum(sld_ref)    AS sld_ref,
           sum(sld_ree)    AS sld_ree,
           sum(sld_jud)    AS sld_jud
    FROM disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg
    GROUP BY codmes, tip_doc, key_value
)
SELECT p.tip_doc,
       p.id_value,
       p.entidad,
       CAST(coalesce(max(CASE WHEN c.codmes = p.codmes_mrm AND c.monto_cast > 0 THEN 1 END), 0) AS INTEGER) AS cast_ori_m0,
       CAST(coalesce(max(CASE WHEN c.codmes = p.m02        AND c.monto_cast > 0 THEN 1 END), 0) AS INTEGER) AS cast_ori_m2,
       CAST(coalesce(max(CASE WHEN c.codmes = p.codmes_mrm AND c.sld_jud    > 0 THEN 1 END), 0) AS INTEGER) AS jud_ori_m0,
       CAST(coalesce(max(CASE WHEN c.codmes = p.m02        AND c.sld_jud    > 0 THEN 1 END), 0) AS INTEGER) AS jud_ori_m2,
       CAST(coalesce(max(CASE WHEN c.codmes = p.codmes_mrm AND c.sld_ref    > 0 THEN 1 END), 0) AS INTEGER) AS ref_ori_m0,
       CAST(coalesce(max(CASE WHEN c.codmes = p.m02        AND c.sld_ref    > 0 THEN 1 END), 0) AS INTEGER) AS ref_ori_m2,
       CAST(coalesce(max(CASE WHEN c.codmes = p.codmes_mrm AND c.sld_ree    > 0 THEN 1 END), 0) AS INTEGER) AS ree_ori_m0,
       CAST(coalesce(max(CASE WHEN c.codmes = p.m02        AND c.sld_ree    > 0 THEN 1 END), 0) AS INTEGER) AS ree_ori_m2,
       CAST(coalesce(max(CASE WHEN e.codmes = p.codmes_mrm AND e.dm_tc      > 0 THEN 1 END), 0) AS INTEGER) AS malo_ori_m0,
       CAST(coalesce(max(CASE WHEN e.codmes = p.m02        AND e.dm_tc      > 0 THEN 1 END), 0) AS INTEGER) AS malo_ori_m2,
       p.codmes_mrm
FROM po p
LEFT JOIN cli c ON c.tip_doc = p.tip_doc AND c.key_value = p.id_value
               AND c.codmes IN (p.codmes_mrm, p.m02)
LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg e ON e.tip_doc = p.tip_doc AND e.key_value = p.id_value
               AND e.entidad = p.entidad AND e.codmes IN (p.codmes_mrm, p.m02)
GROUP BY p.tip_doc, p.id_value, p.entidad, p.codmes_mrm
