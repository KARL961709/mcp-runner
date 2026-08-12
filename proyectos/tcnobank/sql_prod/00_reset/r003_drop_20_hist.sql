-- r003_drop_20_hist.sql | borra la tabla antes de recrearla. Tabla EXTERNA: el DROP no limpia S3, por eso el
-- prefijo del location va versionado y un rebuild reusa la misma ruta.
DROP TABLE IF EXISTS disc_model_owner.ds_adm_tcnb_20_hist
