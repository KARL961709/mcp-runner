-- 94_reset_shap_muestra.sql | borra la muestra SHAP antes de recrearla. Tabla EXTERNA: el DROP no limpia S3, por eso el prefijo va versionado (shap_v1)
DROP TABLE IF EXISTS disc_model_owner.ds_adm_bpe_shap_muestra
