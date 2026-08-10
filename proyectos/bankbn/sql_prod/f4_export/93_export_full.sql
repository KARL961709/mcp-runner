-- 93_export_full.sql | export analitico de ds_adm_bpe_bankbn_cal_202607 INCLUYENDO el bucket 99, que es donde viven los SSFF. Sin key_value ni tip_doc: no hacen falta para el analisis y asi no viajan identificadores
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_cal_full_export
WITH (
    format               = 'PARQUET',
    parquet_compression  = 'SNAPPY',
    external_location    = '<S3_DATOS>/'
) AS
SELECT codmes,
       entidad,
       cod_instit_financiera,
       personeria,
       flg_ppjj,
       flg_clean,
       flg_clean_calib,
       flg_calib,
       pd_raw,
       pd_cal,
       rho_i,
       fhat,
       prob_modelo_cal,
       puntuacion_modelo,
       target_01m, target_02m, target_03m, target_04m, target_05m, target_06m,
       target_07m, target_08m, target_09m, target_10m, target_11m, target_12m,
       segmento_reactiva,
       flg_impulsa,
       flg_impulsa_u12m,
       filtro_top4,
       filtro_pnsn,
       filtro_impulsa_m0,
       filtro_reactiva_puro
FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
