-- ============================================================================
-- a16. Distribucion del nodo en la NUEVA (ds_adm hoy) para meses representativos.
--      Sano = spread real entre NODO 1/2/3, no todo un solo valor (backfill malo).
-- ============================================================================
SELECT
    codmes,
    nodo,
    COUNT(*) AS n
FROM disc_model_owner.altas_adm_pp_cdpp_cal_ttc
WHERE codmes IN ('202310', '202311', '202401', '202506', '202606')
GROUP BY codmes, nodo
ORDER BY codmes, nodo
