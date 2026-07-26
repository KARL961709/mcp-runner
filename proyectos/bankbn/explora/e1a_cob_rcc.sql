-- e1a COBERTURA RCC (particiones)
SELECT 'rcc' AS fuente, MIN(p_codmes) AS mn, MAX(p_codmes) AS mx, COUNT(DISTINCT p_codmes) AS meses
FROM "e_perm_aws"."t_fact_report_rcc_rsk$partitions"
