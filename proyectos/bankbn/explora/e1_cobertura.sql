-- e1 COBERTURA (particiones, barato)
SELECT 'rcc' AS fuente, MIN(p_codmes) AS mn, MAX(p_codmes) AS mx, COUNT(DISTINCT p_codmes) AS meses
FROM "e_perm_aws"."t_fact_report_rcc_rsk$partitions"
UNION ALL
SELECT 'score', MIN(p_codmes), MAX(p_codmes), COUNT(DISTINCT p_codmes)
FROM e_perm_aws.scr_admbankbpe_rsk
