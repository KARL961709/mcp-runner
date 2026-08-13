-- 118_rd_vs_pd_driver.sql | reproduce la hoja 1_clean_dirty del entregable rd_vs_pd_driver en una sola query. Grano poblacion x driver x codmes, con driver GLOBAL mas PNN y PJJ via GROUPING SETS. Las proyecciones V1/V2/V3 NO estan aca: necesitan correr la cadena en python, ver calib_v4/fit/rd_vs_pd_driver.py
SELECT CASE WHEN entidad = 'IBK' THEN 'IBK' ELSE 'RESTO_TOP4' END              AS poblacion,
       COALESCE(CASE WHEN flg_ppjj = 1 THEN 'PJJ' ELSE 'PNN' END, 'GLOBAL')    AS driver,
       codmes,
       count(*)                                                                AS n,
       count(target_12m)                                                       AS n_target,
       CASE WHEN date_diff('month', date_parse(CAST(codmes AS VARCHAR), '%Y%m'),
                           date_parse('202606', '%Y%m')) >= 12
            THEN 'SI' ELSE 'NO' END                                            AS maduro,
       date_diff('month', date_parse(CAST(codmes AS VARCHAR), '%Y%m'),
                 date_parse('202606', '%Y%m'))                                 AS h_disp,
       round(avg(TRY_CAST(fhat AS DOUBLE)), 6)                                 AS fhat,
       round(100.0 * avg(TRY_CAST(pd_raw AS DOUBLE)), 4)                       AS pd_raw_pct,
       round(100.0 * avg(TRY_CAST(prob_modelo_cal AS DOUBLE)), 4)              AS pd_pit_pct,
       round(100.0 * avg(TRY_CAST(target_12m AS DOUBLE)), 4)                   AS rd12_pct,
       round(100.0 * avg(TRY_CAST(target_09m AS DOUBLE)), 4)                   AS rd09_pct,
       round(100.0 * avg(TRY_CAST(target_06m AS DOUBLE)), 4)                   AS rd06_pct,
       round(100.0 * avg(TRY_CAST(target_03m AS DOUBLE)), 4)                   AS rd03_pct,
       sum(TRY_CAST(target_12m AS INTEGER))                                    AS malos_12m
FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
WHERE pd_raw IS NOT NULL
  AND fhat IS NOT NULL
  AND flg_clean_calib <> 99
GROUP BY GROUPING SETS (
    (CASE WHEN entidad = 'IBK' THEN 'IBK' ELSE 'RESTO_TOP4' END,
     CASE WHEN flg_ppjj = 1 THEN 'PJJ' ELSE 'PNN' END,
     codmes),
    (CASE WHEN entidad = 'IBK' THEN 'IBK' ELSE 'RESTO_TOP4' END,
     codmes)
)
ORDER BY poblacion, driver, codmes
