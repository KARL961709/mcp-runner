-- 92_reset_export_full.sql | borra la tabla del export analitico. Es EXTERNA: el DROP no limpia el S3, por eso <S3_DATOS> tiene que apuntar a un prefijo nuevo
DROP TABLE IF EXISTS disc_model_owner.ds_adm_bpe_bankbn_cal_full_export
