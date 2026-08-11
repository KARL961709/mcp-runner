-- 11_insumo_calibracion.sql | v4b: agrega target 01/02/03m. Prefijo nuevo porque la tabla es EXTERNA y el DROP no limpia S3 | insumo unico para re-ajustar la cadena: una fila por operacion con lo minimo que la cadena necesita, sin key_value ni tip_doc. Incluye SSFF para poder backtestear sobre el 87% del libro
CREATE TABLE disc_model_owner.ds_adm_bpe_insumo_calib_v4
WITH (
    format               = 'PARQUET',
    parquet_compression  = 'SNAPPY',
    external_location    = '<S3_DATOS>/calib_v4b/'
) AS
SELECT codmes,
       CAST(substr(CAST(codmes AS VARCHAR), 1, 4) AS INTEGER) * 10
         + CAST(CAST((CAST(substr(CAST(codmes AS VARCHAR), 5, 2) AS INTEGER) + 2) / 3 AS INTEGER) AS INTEGER) AS trimestre,
       CASE WHEN entidad = 'IBK' THEN 'IBK'
            WHEN entidad = 'OTRO' THEN 'SSFF'
            ELSE 'RESTO_TOP4' END                          AS pob,
       entidad,
       cod_instit_financiera,
       personeria,
       flg_ppjj,
       flg_clean,
       flg_clean_calib,
       flg_calib,
       flg_impulsa,
       flg_impulsa_u12m,
       segmento_reactiva,
       TRY_CAST(pd_raw AS DOUBLE)                          AS pd_raw,
       TRY_CAST(fhat AS DOUBLE)                            AS fhat,
       TRY_CAST(pd_cal AS DOUBLE)                          AS pd_cal_vig,
       TRY_CAST(rho_i AS DOUBLE)                           AS rho_i_vig,
       TRY_CAST(prob_modelo_cal AS DOUBLE)                 AS pd_pit_vig,
       TRY_CAST(puntuacion_modelo AS DOUBLE)               AS puntuacion_vig,
       TRY_CAST(target_01m AS INTEGER)                     AS target_01m,
       TRY_CAST(target_02m AS INTEGER)                     AS target_02m,
       TRY_CAST(target_03m AS INTEGER)                     AS target_03m,
       TRY_CAST(target_06m AS INTEGER)                     AS target_06m,
       TRY_CAST(target_09m AS INTEGER)                     AS target_09m,
       TRY_CAST(target_12m AS INTEGER)                     AS target_12m
FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
WHERE pd_raw IS NOT NULL
  AND fhat IS NOT NULL
