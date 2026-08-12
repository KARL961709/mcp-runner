-- 30_reset_base.sql | borra la base de calibracion antes de recrearla. Tabla EXTERNA: el DROP no limpia S3, por eso el prefijo va versionado (tcnobank_v1)
DROP TABLE IF EXISTS disc_model_owner.ds_tcnobank_calib_v1
