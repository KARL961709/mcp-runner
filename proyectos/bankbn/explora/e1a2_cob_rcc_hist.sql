-- e1a2 COBERTURA RCC HISTORICO (d_perm, <=201812)
SELECT 'rcc_hist_dperm' AS fuente, MIN(p_codmes) AS mn, MAX(p_codmes) AS mx, COUNT(DISTINCT p_codmes) AS meses
FROM "d_perm_aws"."t_fact_report_rcc_rsk$partitions"
