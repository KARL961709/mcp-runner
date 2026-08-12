-- 52_profundidad_core.sql | profundidad de las fuentes cuya particion ya conocemos, leyendo SOLO metadata: define hasta donde puede llegar la serie larga del target. Van juntas porque las cinco se usan con p_codmes en el codigo de produccion
SELECT 'RCC  e_perm_aws'          AS fuente, count(*) AS n_meses, min(p_codmes) AS codmes_min, max(p_codmes) AS codmes_max
FROM "e_perm_aws"."t_fact_report_rcc_rsk$partitions"
UNION ALL
SELECT 'RCC  d_perm_aws', count(*), min(p_codmes), max(p_codmes)
FROM "d_perm_aws"."t_fact_report_rcc_rsk$partitions"
UNION ALL
SELECT 'tng_altas_ssff_rsk', count(*), min(p_codmes), max(p_codmes)
FROM "e_perm_aws"."tng_altas_ssff_rsk$partitions"
UNION ALL
SELECT 'tng_altas_ibk_rsk', count(*), min(p_codmes), max(p_codmes)
FROM "e_perm_aws"."tng_altas_ibk_rsk$partitions"
UNION ALL
SELECT 'scr_vcnbank_rsk', count(*), min(p_codmes), max(p_codmes)
FROM "e_perm_aws"."scr_vcnbank_rsk$partitions"
ORDER BY fuente
