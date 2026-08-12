-- 07_per_est_mes.sql | serie mensual de la base de calibracion vigente: universo, elegible sin look-ahead, con target observable y tasa de malos a 12 meses
SELECT p_codmes,
       count(*)                                                                                   AS n_universo,
       sum(CASE WHEN flg_est = 1 THEN 1 ELSE 0 END)                                               AS n_est,
       sum(CASE WHEN flg_per = 1 THEN 1 ELSE 0 END)                                               AS n_per,
       sum(CASE WHEN dsc_flg_malo_12m IN ('BUENO', 'MALO') AND prelacion_12m = 1
                 AND score IS NOT NULL THEN 1 ELSE 0 END)                                         AS n_per12,
       sum(CASE WHEN dsc_flg_malo_12m = 'MALO' AND prelacion_12m = 1
                 AND score IS NOT NULL THEN 1 ELSE 0 END)                                         AS n_malo12,
       round(100.0 * sum(CASE WHEN dsc_flg_malo_12m = 'MALO' AND prelacion_12m = 1
                              AND score IS NOT NULL THEN 1 ELSE 0 END)
             / nullif(sum(CASE WHEN dsc_flg_malo_12m IN ('BUENO', 'MALO') AND prelacion_12m = 1
                                AND score IS NOT NULL THEN 1 ELSE 0 END), 0), 3)                  AS rd_12m,
       round(avg(TRY_CAST(score AS DOUBLE)), 1)                                                   AS score_medio
FROM e_perm_aws.ds_flg_admtcnobk1_rsk
GROUP BY p_codmes
ORDER BY p_codmes
