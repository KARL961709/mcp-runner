-- 90_reset_export.sql | borra la tabla de export. El S3 se limpia aparte: CTAS exige el destino vacio
DROP TABLE IF EXISTS disc_model_owner.ds_adm_bpe_bankbn_cal_export
