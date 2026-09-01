-- e01. Export parquet del fit IBK (row-level, clean+dirty, todas las cohortes, SIN key_value) -> -Bajar.
CREATE TABLE disc_model_owner.tcvc_fit_ibk_export
WITH (format = 'PARQUET', write_compression = 'SNAPPY', external_location = '<S3_DATOS>/tcvc_fit/') AS
SELECT codmes, cod_instit_financiera, flg_ibk, tipo_ingreso, nodo,
       pd_raw, flg_pd_raw, flg_clean, flg_calib, target_01m, target_02m, target_03m, target_04m, target_05m, target_06m, target_07m, target_08m, target_09m, target_10m, target_11m, target_12m
FROM disc_model_owner.ds_adm_tcbank_cal
WHERE flg_ibk = 1