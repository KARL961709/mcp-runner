-- v6_cobertura_mes.sql | G6. Serie mensual del maestro: cuanta poblacion, cuanto sobrevive a cada bucket, la tasa de
-- malos bajo las cuatro definiciones y la PD cruda promedio. Es el tablero que dice si algun mes se rompio.
SELECT codmes_mrm,
       count(*)                                                                          AS n_universo,
       sum(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END)                                   AS n_scope,
       sum(CASE WHEN flg_clean = 1  THEN 1 ELSE 0 END)                                   AS n_clean,
       sum(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN 1 ELSE 0 END)                  AS n_calib,
       sum(CASE WHEN flg_calib = 1 AND flg_clean_macro = 1 THEN 1 ELSE 0 END)            AS n_calib_macro,
       round(100.0 * avg(CASE WHEN flg_calib = 1 AND flg_clean = 1
                              THEN CAST(target_12m      AS DOUBLE) END), 4)              AS rd_pub,
       round(100.0 * avg(CASE WHEN flg_calib = 1 AND flg_clean = 1
                              THEN CAST(target_12m_corr AS DOUBLE) END), 4)              AS rd_corr,
       round(100.0 * avg(CASE WHEN flg_calib = 1 AND flg_clean = 1
                              THEN CAST(target_12m_b30  AS DOUBLE) END), 4)              AS rd_b30,
       round(100.0 * avg(CASE WHEN flg_calib = 1 AND flg_clean = 1
                              THEN CAST(target_12m_full AS DOUBLE) END), 4)              AS rd_full,
       round(100.0 * avg(CASE WHEN flg_calib = 1 AND flg_clean_macro = 1
                              THEN CAST(target_12m_corr AS DOUBLE) END), 4)              AS rd_macro,
       round(100.0 * avg(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN pd_raw END), 4)  AS pd_raw_media,
       sum(falla_madurez)                                                                AS n_inmaduro
FROM disc_model_owner.ds_adm_tcnb_cal
GROUP BY codmes_mrm
ORDER BY codmes_mrm
