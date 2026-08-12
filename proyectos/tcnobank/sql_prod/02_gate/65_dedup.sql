-- ============================================================================
-- 65. DEDUP - PRELACION CON ORDEN TOTAL DETERMINISTA
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_65_dedup
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm']
) AS
SELECT tip_doc,
       id_value,
       entidad,
       CAST(row_number() OVER (PARTITION BY codmes_mrm, tip_doc, id_value
                               ORDER BY entidad ASC) AS INTEGER)                       AS prelacion_cod,
       CAST(row_number() OVER (PARTITION BY codmes_mrm, tip_doc, id_value
                               ORDER BY saldo_tc_ori DESC, entidad ASC) AS INTEGER)    AS prelacion_sld,
       codmes_mrm
FROM disc_model_owner.ds_adm_vcnbank_tc_60_filtros
