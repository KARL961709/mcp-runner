-- ============================================================================
-- 95. SERIE MENSUAL - POBLACION TASAS Y PD CRUDA
--   la serie de RD que alimenta el modelo macro corre sobre flg_hist, sin score
--   la de calibracion corre sobre flg_calib. n_hist debe existir desde 201902
-- ============================================================================
SELECT codmes_mrm,
       count(*)                                                                        AS n_universo,
       sum(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END)                                 AS n_scope,
       sum(CASE WHEN flg_clean = 1  THEN 1 ELSE 0 END)                                 AS n_clean,
       sum(CASE WHEN flg_hist = 1 AND flg_clean = 1 THEN 1 ELSE 0 END)                 AS n_hist,
       sum(CASE WHEN flg_hist = 1 AND flg_clean_macro = 1 THEN 1 ELSE 0 END)           AS n_hist_macro,
       sum(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN 1 ELSE 0 END)                AS n_calib,
       sum(CASE WHEN flg_calib = 1 AND flg_clean_sin_ent = 1 THEN 1 ELSE 0 END)        AS n_calib_sin_ent,
       round(100.0 * avg(CASE WHEN flg_hist = 1 AND flg_clean_macro = 1
                              THEN CAST(target_03m AS DOUBLE) END), 4)                 AS rd_hist_03m,
       round(100.0 * avg(CASE WHEN flg_hist = 1 AND flg_clean_macro = 1
                              THEN CAST(target_06m AS DOUBLE) END), 4)                 AS rd_hist_06m,
       round(100.0 * avg(CASE WHEN flg_hist = 1 AND flg_clean_macro = 1
                              THEN CAST(target_12m AS DOUBLE) END), 4)                 AS rd_hist_12m,
       round(100.0 * avg(CASE WHEN flg_calib = 1 AND flg_clean = 1
                              THEN CAST(target_12m AS DOUBLE) END), 4)                 AS rd_calib_12m,
       round(100.0 * avg(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN pd_raw END), 4) AS pd_raw_media,
       sum(falla_madurez)                                                              AS n_inmaduro
FROM disc_model_owner.ds_adm_vcnbank_tc_cal
GROUP BY codmes_mrm
ORDER BY codmes_mrm
