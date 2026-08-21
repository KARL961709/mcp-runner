-- 1_reset_ds_escopt.sql | dropea SOLO la tabla nueva del escenario optimista del ds (no toca la original ds_adm_bpe_bankbn_cal_202607). Corre ANTES de 2. Tabla gestionada: el DROP limpia S3
DROP TABLE IF EXISTS disc_model_owner.ds_adm_bpe_bankbn_cal_202607_escopt
