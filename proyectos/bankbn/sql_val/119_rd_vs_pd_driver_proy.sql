-- 119_rd_vs_pd_driver_proy.sql | la tabla rd_vs_pd_driver COMPLETA, con las tres proyecciones resueltas en SQL. El multiplicador y el chain-ladder son cocientes de agregados y la regresion logit tiene forma cerrada, asi que los tres salen con funciones de ventana sobre las cosechas maduras de la misma celda. Sin self-join y sin reusar CTE: Trino los inlinea
SELECT poblacion,
       driver,
       codmes,
       maduro,
       h_disp,
       h_base,
       n,
       n_target,
       fhat,
       pd_raw_pct,
       pd_pit_pct,
       rd12_pct,
       rd09_pct,
       rd06_pct,
       rd03_pct,
       CASE WHEN maduro = 'NO' AND rd_base > 0 AND n_ref >= 6
            THEN round(rd_base * mult, 4) END                                   AS proy_V1_pct,
       CASE WHEN maduro = 'NO' AND rd_base > 0 AND n_ref >= 6
            THEN round(rd_base * chain, 4) END                                   AS proy_V2_pct,
       CASE WHEN maduro = 'NO' AND rd_base > 0 AND n_ref >= 6
            THEN round(100.0 / (1.0 + exp(-(reg_a + reg_b * ln(rd_base / (100.0 - rd_base))))), 4) END                                   AS proy_V3_pct,
       CASE WHEN maduro = 'SI' THEN ''
            WHEN h_base >= 6 THEN 'SI'
            ELSE 'NO  h<6' END                                              AS proy_confiable,
       n_ref                                                                AS n_cosechas_ajuste
FROM (
    SELECT c.*,
           CASE h_base WHEN 3 THEN rd03_pct WHEN 6 THEN rd06_pct WHEN 9 THEN rd09_pct END   AS rd_base,
           CASE h_base WHEN 3 THEN sw3 WHEN 6 THEN sw6 WHEN 9 THEN sw9 END   AS n_ref,
           CASE h_base WHEN 3 THEN swr3 / nullif(sw3, 0) WHEN 6 THEN swr6 / nullif(sw6, 0) WHEN 9 THEN swr9 / nullif(sw9, 0) END   AS mult,
           CASE h_base WHEN 3 THEN swy3 / nullif(swx3, 0) WHEN 6 THEN swy6 / nullif(swx6, 0) WHEN 9 THEN swy9 / nullif(swx9, 0) END   AS chain,
           CASE h_base WHEN 3 THEN (sw3 * swxy3 - swlx3 * swly3) / nullif(sw3 * swxx3 - swlx3 * swlx3, 0) WHEN 6 THEN (sw6 * swxy6 - swlx6 * swly6) / nullif(sw6 * swxx6 - swlx6 * swlx6, 0) WHEN 9 THEN (sw9 * swxy9 - swlx9 * swly9) / nullif(sw9 * swxx9 - swlx9 * swlx9, 0) END   AS reg_b,
           CASE h_base WHEN 3 THEN (swly3 - ((sw3 * swxy3 - swlx3 * swly3) / nullif(sw3 * swxx3 - swlx3 * swlx3, 0)) * swlx3) / nullif(sw3, 0) WHEN 6 THEN (swly6 - ((sw6 * swxy6 - swlx6 * swly6) / nullif(sw6 * swxx6 - swlx6 * swlx6, 0)) * swlx6) / nullif(sw6, 0) WHEN 9 THEN (swly9 - ((sw9 * swxy9 - swlx9 * swly9) / nullif(sw9 * swxx9 - swlx9 * swlx9, 0)) * swlx9) / nullif(sw9, 0) END   AS reg_a
    FROM (
        SELECT b.*,
               sum(CASE WHEN maduro = 'SI' AND rd03_pct > 0 AND rd03_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS sw3,
               sum(CASE WHEN maduro = 'SI' AND rd03_pct > 0 AND rd03_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * rd12_pct / rd03_pct AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swr3,
               sum(CASE WHEN maduro = 'SI' AND rd03_pct > 0 AND rd03_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * rd12_pct AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swy3,
               sum(CASE WHEN maduro = 'SI' AND rd03_pct > 0 AND rd03_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * rd03_pct AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swx3,
               sum(CASE WHEN maduro = 'SI' AND rd03_pct > 0 AND rd03_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * ln(rd03_pct / (100.0 - rd03_pct)) AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swlx3,
               sum(CASE WHEN maduro = 'SI' AND rd03_pct > 0 AND rd03_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * ln(rd12_pct / (100.0 - rd12_pct)) AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swly3,
               sum(CASE WHEN maduro = 'SI' AND rd03_pct > 0 AND rd03_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * ln(rd03_pct / (100.0 - rd03_pct)) * ln(rd03_pct / (100.0 - rd03_pct)) AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swxx3,
               sum(CASE WHEN maduro = 'SI' AND rd03_pct > 0 AND rd03_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * ln(rd03_pct / (100.0 - rd03_pct)) * ln(rd12_pct / (100.0 - rd12_pct)) AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swxy3,
               sum(CASE WHEN maduro = 'SI' AND rd06_pct > 0 AND rd06_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS sw6,
               sum(CASE WHEN maduro = 'SI' AND rd06_pct > 0 AND rd06_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * rd12_pct / rd06_pct AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swr6,
               sum(CASE WHEN maduro = 'SI' AND rd06_pct > 0 AND rd06_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * rd12_pct AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swy6,
               sum(CASE WHEN maduro = 'SI' AND rd06_pct > 0 AND rd06_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * rd06_pct AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swx6,
               sum(CASE WHEN maduro = 'SI' AND rd06_pct > 0 AND rd06_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * ln(rd06_pct / (100.0 - rd06_pct)) AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swlx6,
               sum(CASE WHEN maduro = 'SI' AND rd06_pct > 0 AND rd06_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * ln(rd12_pct / (100.0 - rd12_pct)) AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swly6,
               sum(CASE WHEN maduro = 'SI' AND rd06_pct > 0 AND rd06_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * ln(rd06_pct / (100.0 - rd06_pct)) * ln(rd06_pct / (100.0 - rd06_pct)) AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swxx6,
               sum(CASE WHEN maduro = 'SI' AND rd06_pct > 0 AND rd06_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * ln(rd06_pct / (100.0 - rd06_pct)) * ln(rd12_pct / (100.0 - rd12_pct)) AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swxy6,
               sum(CASE WHEN maduro = 'SI' AND rd09_pct > 0 AND rd09_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS sw9,
               sum(CASE WHEN maduro = 'SI' AND rd09_pct > 0 AND rd09_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * rd12_pct / rd09_pct AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swr9,
               sum(CASE WHEN maduro = 'SI' AND rd09_pct > 0 AND rd09_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * rd12_pct AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swy9,
               sum(CASE WHEN maduro = 'SI' AND rd09_pct > 0 AND rd09_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * rd09_pct AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swx9,
               sum(CASE WHEN maduro = 'SI' AND rd09_pct > 0 AND rd09_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * ln(rd09_pct / (100.0 - rd09_pct)) AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swlx9,
               sum(CASE WHEN maduro = 'SI' AND rd09_pct > 0 AND rd09_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * ln(rd12_pct / (100.0 - rd12_pct)) AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swly9,
               sum(CASE WHEN maduro = 'SI' AND rd09_pct > 0 AND rd09_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * ln(rd09_pct / (100.0 - rd09_pct)) * ln(rd09_pct / (100.0 - rd09_pct)) AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swxx9,
               sum(CASE WHEN maduro = 'SI' AND rd09_pct > 0 AND rd09_pct < 100 AND rd12_pct > 0 AND rd12_pct < 100 THEN CAST(n * ln(rd09_pct / (100.0 - rd09_pct)) * ln(rd12_pct / (100.0 - rd12_pct)) AS DOUBLE) ELSE 0 END) OVER (PARTITION BY poblacion, driver)   AS swxy9,
               1 AS pad
        FROM (
            SELECT poblacion,
                   COALESCE(driver, 'GLOBAL')                       AS driver,
                   codmes,
                   maduro,
                   h_disp,
                   CASE WHEN h_disp >= 12 THEN 12
                        WHEN h_disp >=  9 THEN 9
                        WHEN h_disp >=  6 THEN 6
                        WHEN h_disp >=  3 THEN 3
                        ELSE 0 END                                  AS h_base,
                   count(*)                                         AS n,
                   count(t12)                                       AS n_target,
                   round(avg(fhat), 6)                              AS fhat,
                   round(100.0 * avg(pd_crudo), 4)                  AS pd_raw_pct,
                   round(100.0 * avg(pd_pit), 4)                    AS pd_pit_pct,
                   round(100.0 * avg(CAST(t12 AS DOUBLE)), 4)       AS rd12_pct,
                   round(100.0 * avg(CAST(t09 AS DOUBLE)), 4)       AS rd09_pct,
                   round(100.0 * avg(CAST(t06 AS DOUBLE)), 4)       AS rd06_pct,
                   round(100.0 * avg(CAST(t03 AS DOUBLE)), 4)       AS rd03_pct
            FROM (
                SELECT CASE WHEN entidad = 'IBK' THEN 'IBK' ELSE 'RESTO_TOP4' END   AS poblacion,
                       CASE WHEN flg_ppjj = 1 THEN 'PJJ' ELSE 'PNN' END             AS driver,
                       codmes,
                       CASE WHEN date_diff('month', date_parse(CAST(codmes AS VARCHAR), '%Y%m'),
                                           date_parse('202606', '%Y%m')) >= 12
                            THEN 'SI' ELSE 'NO' END                                 AS maduro,
                       date_diff('month', date_parse(CAST(codmes AS VARCHAR), '%Y%m'),
                                 date_parse('202606', '%Y%m'))                      AS h_disp,
                       TRY_CAST(fhat AS DOUBLE)                                     AS fhat,
                       TRY_CAST(pd_raw AS DOUBLE)                                   AS pd_crudo,
                       TRY_CAST(prob_modelo_cal AS DOUBLE)                          AS pd_pit,
                       TRY_CAST(target_12m AS INTEGER)                              AS t12,
                       TRY_CAST(target_09m AS INTEGER)                              AS t09,
                       TRY_CAST(target_06m AS INTEGER)                              AS t06,
                       TRY_CAST(target_03m AS INTEGER)                              AS t03
                FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
                WHERE pd_raw IS NOT NULL
                  AND fhat IS NOT NULL
                  AND flg_clean_calib <> 99
            ) r
            GROUP BY GROUPING SETS (
                (poblacion, driver, codmes, maduro, h_disp),
                (poblacion, codmes, maduro, h_disp)
            )
        ) b
    ) c
) w
ORDER BY poblacion, driver, codmes
