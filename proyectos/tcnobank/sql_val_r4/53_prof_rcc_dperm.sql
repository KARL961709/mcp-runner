-- 53_prof_rcc_dperm.sql | misma medicion sobre d_perm_aws, el esquema que menciono el usuario. Si una de las dos copias llega mas atras, esa manda para la serie larga
SELECT substr(p_codmes, 1, 4)   AS anio,
       count(*)                 AS n_meses,
       min(p_codmes)            AS codmes_min,
       max(p_codmes)            AS codmes_max
FROM "d_perm_aws"."t_fact_report_rcc_rsk$partitions"
GROUP BY substr(p_codmes, 1, 4)
ORDER BY anio
