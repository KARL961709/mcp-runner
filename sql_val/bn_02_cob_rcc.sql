-- ============================================================================
-- BN 02. COBERTURA RCC (via particiones)
-- ============================================================================
SELECT
    MIN(p_codmes)             AS min_pcodmes,
    MAX(p_codmes)             AS max_pcodmes,
    COUNT(DISTINCT p_codmes)  AS meses
FROM "e_perm_aws"."t_fact_report_rcc_rsk$partitions"
;
