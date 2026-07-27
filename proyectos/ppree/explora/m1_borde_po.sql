-- ============================================================================
-- M1. BORDE DE LA PO. 10_po asume e_perm hasta 202607 sin medirlo, y
--     nuevos_insumos.sql declara 202101-202604 (CIT, no OBS). Si la PO termina
--     antes, el borde derecho del rebuild no es 202606.
-- ============================================================================
SELECT 'd_perm.ds_compppibk_rsk' AS fuente,
       SUBSTR(CAST(codmes AS VARCHAR), 1, 4)             AS anio,
       COUNT(*)                                          AS n,
       COUNT(DISTINCT CAST(codmes AS VARCHAR))           AS n_meses,
       MIN(CAST(codmes AS VARCHAR))                      AS mes_min,
       MAX(CAST(codmes AS VARCHAR))                      AS mes_max
FROM d_perm_aws.ds_compppibk_rsk
GROUP BY 1, 2
UNION ALL
SELECT 'e_perm.scr_compppibk_rsk',
       SUBSTR(CAST(codmes AS VARCHAR), 1, 4),
       COUNT(*), COUNT(DISTINCT CAST(codmes AS VARCHAR)),
       MIN(CAST(codmes AS VARCHAR)), MAX(CAST(codmes AS VARCHAR))
FROM e_perm_aws.scr_compppibk_rsk
GROUP BY 1, 2
ORDER BY 1, 2
