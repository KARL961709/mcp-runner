-- 00_dimension_insumo.sql | dimensiona el insumo de calibracion antes de exportarlo, para no construir un parquet a ciegas
SELECT CASE WHEN entidad = 'IBK' THEN 'IBK'
            WHEN entidad = 'OTRO' THEN 'SSFF'
            ELSE 'RESTO_TOP4' END                                    AS pob,
       flg_clean,
       flg_calib,
       CASE WHEN target_12m IS NULL THEN 0 ELSE 1 END                AS evaluable,
       count(*)                                                      AS n,
       min(codmes)                                                   AS codmes_min,
       max(codmes)                                                   AS codmes_max,
       count(DISTINCT codmes)                                        AS meses,
       sum(CASE WHEN flg_impulsa = 1 THEN 1 ELSE 0 END)              AS n_impulsa,
       round(100.0 * avg(TRY_CAST(pd_raw AS DOUBLE)), 4)             AS pd_raw_media,
       round(100.0 * avg(TRY_CAST(target_12m AS DOUBLE)), 4)         AS rd_12m,
       sum(CASE WHEN fhat IS NULL THEN 1 ELSE 0 END)                 AS sin_fhat,
       sum(CASE WHEN pd_raw IS NULL THEN 1 ELSE 0 END)               AS sin_pd_raw
FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
GROUP BY 1, flg_clean, flg_calib, 4
ORDER BY 1, flg_clean, flg_calib, 4
