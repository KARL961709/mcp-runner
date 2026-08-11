-- 10_reset_insumo.sql | borra el insumo de calibracion antes de recrearlo. Tabla EXTERNA: el DROP no limpia S3, por eso el prefijo va versionado (calib_v4)
DROP TABLE IF EXISTS disc_model_owner.ds_adm_bpe_insumo_calib_v4
