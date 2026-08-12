-- 00_reset_rcc_agg.sql | borra la capa agregada del RCC antes de recrearla. Tabla EXTERNA: el DROP no limpia S3, por eso el prefijo va versionado (tcnobank_v1)
DROP TABLE IF EXISTS disc_model_owner.ds_tcnobank_rcc_agg_v1
