-- v_s2_cast.sql | probabilidad no nula que NO castea a double, y rango de valores
SELECT count(1)                                                                    AS filas,
       sum(CASE WHEN probabilidad IS NOT NULL
                 AND TRY_CAST(probabilidad AS double) IS NULL THEN 1 ELSE 0 END)   AS no_castea,
       sum(CASE WHEN TRY_CAST(probabilidad AS double) < 0
                  OR TRY_CAST(probabilidad AS double) > 1 THEN 1 ELSE 0 END)       AS fuera_0_1,
       min(TRY_CAST(probabilidad AS double))                                       AS pd_min,
       max(TRY_CAST(probabilidad AS double))                                       AS pd_max,
       avg(TRY_CAST(probabilidad AS double))                                       AS pd_prom
FROM e_perm_aws.scr_admbankbpe_rsk
