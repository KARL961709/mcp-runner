-- ============================================================================
-- BN 01. COBERTURA SCORE (pd_raw)
-- ============================================================================
SELECT
    MIN(p_codmes)              AS min_pcodmes,
    MAX(p_codmes)              AS max_pcodmes,
    COUNT(DISTINCT p_codmes)   AS meses,
    COUNT(*)                   AS filas
FROM e_perm_aws.scr_admbankbpe_rsk
;
