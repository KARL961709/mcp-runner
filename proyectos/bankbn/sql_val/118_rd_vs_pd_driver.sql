-- 118_rd_vs_pd_driver.sql | reproduce la hoja 1_clean_dirty del entregable rd_vs_pd_driver en una sola query. Grano poblacion x driver x codmes, con driver GLOBAL mas PNN y PJJ via GROUPING SETS sobre columnas de la subconsulta, porque Trino no acepta expresiones ahi. Las proyecciones V1/V2/V3 NO estan: necesitan python, ver calib_v4/fit/rd_vs_pd_driver.py
SELECT poblacion,
       COALESCE(driver, 'GLOBAL')                                  AS driver,
       codmes,
       maduro,
       h_disp,
       count(*)                                                    AS n,
       count(t12)                                                  AS n_target,
       round(avg(fhat), 6)                                         AS fhat,
       round(100.0 * avg(pd_crudo), 4)                             AS pd_raw_pct,
       round(100.0 * avg(pd_pit), 4)                               AS pd_pit_pct,
       round(100.0 * avg(CAST(t12 AS DOUBLE)), 4)                  AS rd12_pct,
       round(100.0 * avg(CAST(t09 AS DOUBLE)), 4)                  AS rd09_pct,
       round(100.0 * avg(CAST(t06 AS DOUBLE)), 4)                  AS rd06_pct,
       round(100.0 * avg(CAST(t03 AS DOUBLE)), 4)                  AS rd03_pct,
       sum(t12)                                                    AS malos_12m
FROM (
    SELECT CASE WHEN entidad = 'IBK' THEN 'IBK' ELSE 'RESTO_TOP4' END      AS poblacion,
           CASE WHEN flg_ppjj = 1 THEN 'PJJ' ELSE 'PNN' END                AS driver,
           codmes,
           CASE WHEN date_diff('month', date_parse(CAST(codmes AS VARCHAR), '%Y%m'),
                               date_parse('202606', '%Y%m')) >= 12
                THEN 'SI' ELSE 'NO' END                                    AS maduro,
           date_diff('month', date_parse(CAST(codmes AS VARCHAR), '%Y%m'),
                     date_parse('202606', '%Y%m'))                         AS h_disp,
           TRY_CAST(fhat AS DOUBLE)                                        AS fhat,
           TRY_CAST(pd_raw AS DOUBLE)                                      AS pd_crudo,
           TRY_CAST(prob_modelo_cal AS DOUBLE)                             AS pd_pit,
           TRY_CAST(target_12m AS INTEGER)                                 AS t12,
           TRY_CAST(target_09m AS INTEGER)                                 AS t09,
           TRY_CAST(target_06m AS INTEGER)                                 AS t06,
           TRY_CAST(target_03m AS INTEGER)                                 AS t03
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
    WHERE pd_raw IS NOT NULL
      AND fhat IS NOT NULL
      AND flg_clean_calib <> 99
) q
GROUP BY GROUPING SETS (
    (poblacion, driver, codmes, maduro, h_disp),
    (poblacion, codmes, maduro, h_disp)
)
ORDER BY poblacion, driver, codmes
