-- ============================================================================
-- 50. TARGETS 1M A 12M - ACUMULADOS Y CON MADUREZ POR HORIZONTE
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_50_targets
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm'],
    external_location   = '<S3_DATOS>/adm_vcnbank_tc_50_targets/'
) AS
WITH po AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad, date_format(date_add('month', 1, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS p01
    FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
),
cli AS (
    SELECT codmes, tip_doc, key_value,
           CASE WHEN coalesce(monto_cast,0) > 0 OR coalesce(sld_jud,0) > 0
                  OR coalesce(sld_ref,0)    > 0 OR coalesce(sld_ree,0) > 0
                THEN 1 ELSE 0 END                                                      AS duro
    FROM (
        SELECT codmes, tip_doc, key_value,
               sum(monto_cast) AS monto_cast, sum(sld_jud) AS sld_jud,
               sum(sld_ref)    AS sld_ref,    sum(sld_ree) AS sld_ree
        FROM disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg
        GROUP BY codmes, tip_doc, key_value) z
),
fut AS (
    SELECT p.codmes_mrm, p.tip_doc, p.id_value, p.entidad,
           CAST(12 - count(DISTINCT e.codmes) AS INTEGER)                              AS missing_12,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 1, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_tc END) AS max_dm_01m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 2, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_tc END) AS max_dm_02m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 3, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_tc END) AS max_dm_03m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 4, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_tc END) AS max_dm_04m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 5, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_tc END) AS max_dm_05m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 6, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_tc END) AS max_dm_06m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 7, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_tc END) AS max_dm_07m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 8, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_tc END) AS max_dm_08m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 9, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_tc END) AS max_dm_09m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 10, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_tc END) AS max_dm_10m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 11, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_tc END) AS max_dm_11m,
       max(CASE WHEN e.codmes BETWEEN p.p01 AND date_format(date_add('month', 12, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') THEN e.dm_tc END) AS max_dm_12m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 1, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_01m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 2, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_02m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 3, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_03m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 4, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_04m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 5, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_05m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 6, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_06m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 7, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_07m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 8, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_08m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 9, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_09m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 10, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_10m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 11, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_11m,
       max(CASE WHEN c.codmes BETWEEN p.p01 AND date_format(date_add('month', 12, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m') AND c.duro = 1 THEN 1 ELSE 0 END) AS duro_12m
    FROM po p
    LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg e ON e.tip_doc = p.tip_doc AND e.key_value = p.id_value
                                AND e.entidad = p.entidad
                                AND e.codmes BETWEEN p.p01 AND date_format(date_add('month', 12, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m')
    LEFT JOIN cli c ON c.tip_doc = p.tip_doc AND c.key_value = p.id_value
                   AND c.codmes BETWEEN p.p01 AND date_format(date_add('month', 12, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m')
    GROUP BY p.codmes_mrm, p.tip_doc, p.id_value, p.entidad
)
SELECT tip_doc,
       id_value,
       entidad,
       missing_12,
       max_dm_12m                                                                      AS max_dm_fut,
       CAST(coalesce(duro_12m, 0) AS INTEGER)                                          AS f_evento_fut,
       CAST(CASE WHEN date_format(date_add('month', 12, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN 1 ELSE 0 END AS INTEGER)                          AS falla_madurez,
       CASE WHEN date_format(date_add('month', 1, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_dm_01m, 0) > 60 OR coalesce(duro_01m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_01m,
       CASE WHEN date_format(date_add('month', 2, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_dm_02m, 0) > 60 OR coalesce(duro_02m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_02m,
       CASE WHEN date_format(date_add('month', 3, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_dm_03m, 0) > 60 OR coalesce(duro_03m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_03m,
       CASE WHEN date_format(date_add('month', 4, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_dm_04m, 0) > 60 OR coalesce(duro_04m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_04m,
       CASE WHEN date_format(date_add('month', 5, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_dm_05m, 0) > 60 OR coalesce(duro_05m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_05m,
       CASE WHEN date_format(date_add('month', 6, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_dm_06m, 0) > 60 OR coalesce(duro_06m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_06m,
       CASE WHEN date_format(date_add('month', 7, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_dm_07m, 0) > 60 OR coalesce(duro_07m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_07m,
       CASE WHEN date_format(date_add('month', 8, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_dm_08m, 0) > 60 OR coalesce(duro_08m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_08m,
       CASE WHEN date_format(date_add('month', 9, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_dm_09m, 0) > 60 OR coalesce(duro_09m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_09m,
       CASE WHEN date_format(date_add('month', 10, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_dm_10m, 0) > 60 OR coalesce(duro_10m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_10m,
       CASE WHEN date_format(date_add('month', 11, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_dm_11m, 0) > 60 OR coalesce(duro_11m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_11m,
       CASE WHEN date_format(date_add('month', 12, date_parse(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN NULL
            WHEN coalesce(max_dm_12m, 0) > 60 OR coalesce(duro_12m, 0) = 1 THEN 1
            ELSE 0 END                           AS target_12m,
       codmes_mrm
FROM fut
