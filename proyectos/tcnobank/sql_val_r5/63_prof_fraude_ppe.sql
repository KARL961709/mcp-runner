-- 63_prof_fraude_ppe.sql | profundidad de las dos fuentes que quedaron sin medir. t_mst_fraude_rsk si tiene p_codmes, asi que puede ser historica y no una foto. t_gdp_rcc_ppe alimenta el swap inferido y solo aparece en d_perm_aws
SELECT 'd_perm_aws.t_mst_fraude_rsk'   AS fuente, count(*) AS n_meses, min(p_codmes) AS codmes_min, max(p_codmes) AS codmes_max
FROM "d_perm_aws"."t_mst_fraude_rsk$partitions"
UNION ALL
SELECT 'e_perm_aws.t_mst_fraude_rsk', count(*), min(p_codmes), max(p_codmes)
FROM "e_perm_aws"."t_mst_fraude_rsk$partitions"
UNION ALL
SELECT 'd_perm_aws.t_gdp_rcc_ppe', count(*), min(p_codmes), max(p_codmes)
FROM "d_perm_aws"."t_gdp_rcc_ppe$partitions"
ORDER BY fuente
