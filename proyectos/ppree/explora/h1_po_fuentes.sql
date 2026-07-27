-- ============================================================================
-- H1. A13 - VIABILIDAD DE LA RECONSTRUCCION 2019-2021: fuentes de la PO.
--     Un mes con particion declarada no es un mes con filas: se cuentan filas.
-- ============================================================================
SELECT 'd_perm.ds_compppibk_rsk' AS fuente,
       SUBSTR(CAST(codmes AS VARCHAR), 1, 4)                    AS anio,
       COUNT(*)                                                 AS n,
       COUNT(DISTINCT CAST(codmes AS VARCHAR))                  AS n_meses_con_filas,
       MIN(CAST(codmes AS VARCHAR))                             AS mes_min,
       MAX(CAST(codmes AS VARCHAR))                             AS mes_max,
       MIN(LENGTH(CAST(key_value AS VARCHAR)))                  AS len_min_key,
       MAX(LENGTH(CAST(key_value AS VARCHAR)))                  AS len_max_key
FROM d_perm_aws.ds_compppibk_rsk
WHERE CAST(codmes AS INT) BETWEEN 201801 AND 202112
GROUP BY 1, 2
UNION ALL
SELECT 'e_perm.scr_compppibk_rsk',
       SUBSTR(CAST(codmes AS VARCHAR), 1, 4),
       COUNT(*), COUNT(DISTINCT CAST(codmes AS VARCHAR)),
       MIN(CAST(codmes AS VARCHAR)), MAX(CAST(codmes AS VARCHAR)),
       MIN(LENGTH(CAST(key_value AS VARCHAR))), MAX(LENGTH(CAST(key_value AS VARCHAR)))
FROM e_perm_aws.scr_compppibk_rsk
WHERE CAST(codmes AS INT) BETWEEN 201801 AND 202112
GROUP BY 1, 2
ORDER BY 1, 2
