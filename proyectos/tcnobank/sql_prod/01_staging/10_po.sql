-- ============================================================================
-- 10. POBLACION OBJETIVO - ALTA DE TC DERIVADA DEL RCC
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_10_po
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm'],
    external_location   = '<S3_DATOS>/adm_vcnbank_tc_10_po/'
) AS
WITH tc AS (
    SELECT codmes, tip_doc, key_value, entidad, saldo_tc
    FROM disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg
    WHERE flg_tc = 1
)
SELECT a.tip_doc,
       a.key_value                                                                     AS id_value,
       a.entidad,
       a.saldo_tc                                                                      AS saldo_tc_ori,
       a.codmes                                                                        AS codmes_mrm
FROM tc a
LEFT JOIN tc b
       ON b.tip_doc   = a.tip_doc
      AND b.key_value = a.key_value
      AND b.entidad   = a.entidad
      AND b.codmes   >= date_format(date_add('month', -12, date_parse(a.codmes, '%Y%m')), '%Y%m')
      AND b.codmes   <= date_format(date_add('month', -1, date_parse(a.codmes, '%Y%m')), '%Y%m')
WHERE a.codmes BETWEEN '201902' AND '202605'
  AND b.key_value IS NULL
