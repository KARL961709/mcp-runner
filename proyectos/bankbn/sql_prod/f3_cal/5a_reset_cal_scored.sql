-- 5a_reset_cal_scored.sql | borra la tabla scoreada de altas. Corre ANTES de 5b. Es tabla gestionada por Athena, asi que el DROP tambien limpia el S3
DROP TABLE IF EXISTS disc_model_owner.ds_adm_bpe_bankbn_cal_202607
