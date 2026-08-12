-- 15_denominador_rd.sql | reconcilia el denominador de la tasa de malos y cuantifica los defaults que la cascada deja fuera por evaluar la mora antes que el evento de castigo, judicial o refinanciado
SELECT CASE WHEN dsc_flg_malo_12m IN ('BUENO', 'MALO')                              THEN '1.base BUENO+MALO'
            WHEN dsc_flg_malo_12m IN ('UNCASHED', 'INSUFICIENTE', 'INDETERMINADO')  THEN '2.sin target por mora'
            WHEN dsc_flg_malo_12m IN ('SWAPS P12M', 'REPRO P12M')                   THEN '3.excluido a futuro'
            ELSE '4.excluido origen o pasado' END                                   AS bloque,
       count(*)                                                                     AS n,
       sum(CASE WHEN prelacion_00m = 1 THEN 1 ELSE 0 END)                           AS n_prel00,
       sum(CASE WHEN flg_est = 1 THEN 1 ELSE 0 END)                                 AS n_est,
       sum(CASE WHEN dsc_flg_malo_12m = 'MALO' THEN 1 ELSE 0 END)                   AS n_malo,
       sum(CASE WHEN coalesce(flg_cstg_12m, 0) = 1 OR coalesce(flg_jdcl_12m, 0) = 1
                  OR coalesce(flg_rfnc_12m, 0) = 1 OR coalesce(flg_rstr_12m, 0) = 1
                THEN 1 ELSE 0 END)                                                  AS n_evento_12m,
       sum(CASE WHEN max_dm_12m > 60 THEN 1 ELSE 0 END)                             AS n_dm60_12m
FROM e_perm_aws.ds_flg_admtcnobk1_rsk
GROUP BY 1
ORDER BY 1
