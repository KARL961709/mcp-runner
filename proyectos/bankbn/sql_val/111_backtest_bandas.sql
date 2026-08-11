-- 111_backtest_bandas.sql | prueba directa de si la PD calibrada v3 acierta por banda en cada poblacion. Devuelve n y defaults crudos para calcular el intervalo del lado de la fabrica
SELECT pob,
       flg_clean,
       banda,
       n,
       round(100.0 * pd_media, 4)   AS pd_media,
       def_12m,
       round(100.0 * rd_12m, 4)     AS rd_12m,
       def_03m,
       round(100.0 * rd_03m, 4)     AS rd_03m,
       round(punt_media, 1)         AS punt_media,
       round(100.0 * pd_raw_media, 4) AS pd_raw_media
FROM (
    SELECT CASE WHEN entidad = 'IBK' THEN 'IBK'
                WHEN entidad = 'OTRO' THEN 'SSFF'
                ELSE 'RESTO_TOP4' END                              AS pob,
           flg_clean,
           CASE WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.02 THEN '01  menos de 2'
                WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.04 THEN '02  2 a 4'
                WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.06 THEN '03  4 a 6'
                WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.08 THEN '04  6 a 8'
                WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.10 THEN '05  8 a 10'
                WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.13 THEN '06  10 a 13'
                WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.16 THEN '07  13 a 16'
                WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.20 THEN '08  16 a 20'
                WHEN TRY_CAST(prob_modelo_cal AS DOUBLE) <  0.30 THEN '09  20 a 30'
                ELSE '10  30 o mas' END                            AS banda,
           count(*)                                                AS n,
           avg(TRY_CAST(prob_modelo_cal AS DOUBLE))                AS pd_media,
           avg(TRY_CAST(pd_raw AS DOUBLE))                         AS pd_raw_media,
           avg(TRY_CAST(puntuacion_modelo AS DOUBLE))              AS punt_media,
           sum(TRY_CAST(target_12m AS INTEGER))                    AS def_12m,
           avg(TRY_CAST(target_12m AS DOUBLE))                     AS rd_12m,
           sum(TRY_CAST(target_03m AS INTEGER))                    AS def_03m,
           avg(TRY_CAST(target_03m AS DOUBLE))                     AS rd_03m
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
    WHERE flg_calib = 1
      AND prob_modelo_cal IS NOT NULL
    GROUP BY 1, flg_clean, 3
) q
ORDER BY pob, flg_clean, banda
