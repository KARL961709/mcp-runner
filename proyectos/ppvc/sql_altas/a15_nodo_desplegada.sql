-- ============================================================================
-- a15. Estado del nodo en la DESPLEGADA por codmes: cuantos en blanco y cuantos
--      valores distintos. Confirma que nodo esta vacio desde 202311 (snapshot viejo).
-- ============================================================================
SELECT
    codmes,
    COUNT(*) AS n,
    SUM(CASE WHEN nodo IS NULL OR nodo = '' THEN 1 ELSE 0 END) AS n_nodo_blank,
    count(DISTINCT nodo) AS n_nodo_distintos
FROM disc_model_owner.altas_adm_pp_cdpp_cal
GROUP BY codmes
ORDER BY codmes
