-- 10_entidad_en_flg.sql | entidades presentes en la tabla de flags vigente y cuales sobreviven a flg_est y flg_per, que es donde muerde el filtro de 5 entidades
SELECT nombre_instit_financiera,
       count(*)                                                                          AS n,
       sum(CASE WHEN flg_est = 1 THEN 1 ELSE 0 END)                                      AS n_est,
       sum(CASE WHEN flg_per = 1 THEN 1 ELSE 0 END)                                      AS n_per,
       sum(CASE WHEN dsc_flg_malo_12m = 'ENTIDADES' THEN 1 ELSE 0 END)                   AS n_excl_entidades,
       sum(CASE WHEN dsc_flg_malo_12m = 'MALO' THEN 1 ELSE 0 END)                        AS n_malo12
FROM e_perm_aws.ds_flg_admtcnobk1_rsk
GROUP BY nombre_instit_financiera
ORDER BY n DESC
LIMIT 45
