-- 112_cobertura_flg_calib.sql | que poblacion es evaluable segun flg_calib y hasta que codmes, para saber sobre que se puede backtestear
SELECT CASE WHEN entidad = 'IBK' THEN 'IBK'
            WHEN entidad = 'OTRO' THEN 'SSFF'
            ELSE 'RESTO_TOP4' END                                       AS pob,
       flg_calib,
       flg_clean,
       count(*)                                                         AS n,
       min(codmes)                                                      AS codmes_min,
       max(codmes)                                                      AS codmes_max,
       count(target_12m)                                                AS con_target_12m,
       count(target_03m)                                                AS con_target_03m,
       round(100.0 * avg(TRY_CAST(target_12m AS DOUBLE)), 4)            AS rd_12m,
       round(100.0 * avg(TRY_CAST(prob_modelo_cal AS DOUBLE)), 4)       AS pd_media
FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
WHERE pd_raw IS NOT NULL
GROUP BY 1, flg_calib, flg_clean
ORDER BY 1, flg_calib, flg_clean
