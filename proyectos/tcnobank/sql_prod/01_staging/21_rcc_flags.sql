-- ============================================================================
-- 21. HISTORICOS U6M U12M U24M
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_21_rcc_flags
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm']
) AS
WITH po AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad,
           date_format(date_add('month', -2, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS m02, date_format(date_add('month', -7, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS m07, date_format(date_add('month', -13, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS m13, date_format(date_add('month', -25, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS m25
    FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
),
cli AS (
    SELECT codmes, tip_doc, key_value,
           sum(monto_cast)     AS monto_cast,
           sum(sld_ref)        AS sld_ref,
           sum(sld_jud)        AS sld_jud,
           sum(sld_bank)       AS sld_bank,
           max(clasif_max)     AS clasif_max,
           max(flg_no_consumo) AS flg_no_consumo
    FROM disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg
    GROUP BY codmes, tip_doc, key_value
)
SELECT p.tip_doc,
       p.id_value,
       p.entidad,
       CAST(coalesce(max(CASE WHEN c.codmes BETWEEN p.m13 AND p.m02 AND c.sld_bank   > 0 THEN 1 END), 0) AS INTEGER) AS banc_u12m,
       CAST(coalesce(max(CASE WHEN c.codmes BETWEEN p.m25 AND p.m02 AND c.monto_cast > 0 THEN 1 END), 0) AS INTEGER) AS cast_u24m,
       CAST(coalesce(max(CASE WHEN c.codmes BETWEEN p.m25 AND p.m02 AND c.sld_jud    > 0 THEN 1 END), 0) AS INTEGER) AS jud_u24m,
       CAST(coalesce(max(CASE WHEN c.codmes BETWEEN p.m07 AND p.m02 AND c.sld_ref    > 0 THEN 1 END), 0) AS INTEGER) AS ref_u6m,
       CAST(coalesce(max(CASE WHEN c.codmes = p.m02 AND c.clasif_max IN ('2','3','4') THEN 1 END), 0) AS INTEGER)    AS mayor_cpp,
       CAST(coalesce(max(CASE WHEN c.codmes BETWEEN p.m25 AND p.m02 AND c.flg_no_consumo = 1 THEN 1 END), 0) AS INTEGER) AS ctrl_no_consumo,
       CAST(CASE WHEN count(c.codmes) = 0 THEN 1 ELSE 0 END AS INTEGER)                AS falla_sin_historia,
       p.codmes_mrm
FROM po p
LEFT JOIN cli c ON c.tip_doc = p.tip_doc AND c.key_value = p.id_value
               AND c.codmes BETWEEN p.m25 AND p.m02
GROUP BY p.tip_doc, p.id_value, p.entidad, p.codmes_mrm
