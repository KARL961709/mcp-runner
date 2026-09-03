-- e01. Export parquet del fit IBK (row-level, todo flg_clean=1, todas las cohortes, SIN key_value, CON sub_producto para 2 modelos). 1 a 1 con ds_ec_cdd_cal WHERE flg_ibk=1. -Bajar.
CREATE TABLE disc_model_owner.ecvc_fit_ibk_export
WITH (format = 'PARQUET', write_compression = 'SNAPPY', external_location = '<S3_DATOS>/ecvc_fit/') AS
SELECT CAST(codmes AS varchar) AS codmes, cod_instit_financiera, flg_ibk, sub_producto, tipo_ingreso, nodo,
       pd_raw, flg_pd_raw, flg_clean, flg_calib,
       target_01m, target_02m, target_03m, target_04m, target_05m, target_06m, target_07m, target_08m, target_09m, target_10m, target_11m, target_12m
FROM disc_model_owner.ds_ec_cdd_cal
WHERE flg_ibk = 1
