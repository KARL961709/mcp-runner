-- 26_fuga_detalle.sql | desglosa por motivo y tipo de evento los defaults que la cascada deja fuera, para decidir si se corrige el orden o se documenta el sesgo
SELECT dsc_flg_malo_12m                                                       AS motivo,
       count(*)                                                               AS n,
       sum(CASE WHEN coalesce(flg_cstg_12m, 0) = 1 THEN 1 ELSE 0 END)         AS n_castigo,
       sum(CASE WHEN coalesce(flg_jdcl_12m, 0) = 1 THEN 1 ELSE 0 END)         AS n_judicial,
       sum(CASE WHEN coalesce(flg_rfnc_12m, 0) = 1 THEN 1 ELSE 0 END)         AS n_refin,
       sum(CASE WHEN coalesce(flg_rstr_12m, 0) = 1 THEN 1 ELSE 0 END)         AS n_reestr,
       sum(CASE WHEN coalesce(flg_cstg_12m, 0) = 1 OR coalesce(flg_jdcl_12m, 0) = 1
                  OR coalesce(flg_rfnc_12m, 0) = 1 OR coalesce(flg_rstr_12m, 0) = 1
                THEN 1 ELSE 0 END)                                            AS n_evento,
       sum(CASE WHEN flg_est = 1 THEN 1 ELSE 0 END)                           AS n_est,
       round(avg(TRY_CAST(max_dm_12m AS DOUBLE)), 1)                          AS dm12_medio
FROM e_perm_aws.ds_flg_admtcnobk1_rsk
WHERE dsc_flg_malo_12m IN ('UNCASHED', 'INSUFICIENTE', 'INDETERMINADO')
GROUP BY dsc_flg_malo_12m
ORDER BY dsc_flg_malo_12m
