-- 11_banda_indeterminado.sql | mide cuanta poblacion cambia de clase al mover la banda de indeterminado de 9-60 (criterio vigente) a 30-60 (criterio de los scripts nuevos)
SELECT CASE WHEN max_dm_12m IS NULL       THEN '0.sin dm'
            WHEN max_dm_12m = 0           THEN '1.dm 00'
            WHEN max_dm_12m BETWEEN 1 AND 8   THEN '2.dm 01-08'
            WHEN max_dm_12m BETWEEN 9 AND 29  THEN '3.dm 09-29'
            WHEN max_dm_12m BETWEEN 30 AND 60 THEN '4.dm 30-60'
            ELSE '5.dm 60+' END                                        AS tramo_dm12,
       count(*)                                                        AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 3)              AS pct,
       sum(CASE WHEN flg_est = 1 THEN 1 ELSE 0 END)                    AS n_est,
       sum(CASE WHEN dsc_flg_malo_12m = 'MALO' THEN 1 ELSE 0 END)      AS n_malo12,
       sum(CASE WHEN dsc_flg_malo_12m = 'BUENO' THEN 1 ELSE 0 END)     AS n_bueno12,
       sum(CASE WHEN dsc_flg_malo_12m = 'INDETERMINADO' THEN 1 ELSE 0 END) AS n_indeterm12
FROM e_perm_aws.ds_flg_admtcnobk1_rsk
GROUP BY 1
ORDER BY 1
