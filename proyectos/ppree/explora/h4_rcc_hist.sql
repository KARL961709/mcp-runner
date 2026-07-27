-- ============================================================================
-- H4. A13 - Los dos t_fact_report_rcc_rsk (rama MALO EN EL SF). Necesario en
--     T0-1, o sea 201812-202111. Conteo por anio SIN filtros de columna.
-- ============================================================================
SELECT 'd_perm.t_fact_report_rcc_rsk' AS fuente,
       SUBSTR(CAST(codmes AS VARCHAR), 1, 4)                    AS anio,
       COUNT(*)                                                 AS n,
       COUNT(DISTINCT CAST(codmes AS VARCHAR))                  AS n_meses_con_filas,
       MIN(CAST(codmes AS VARCHAR))                             AS mes_min,
       MAX(CAST(codmes AS VARCHAR))                             AS mes_max
FROM d_perm_aws.t_fact_report_rcc_rsk
WHERE CAST(codmes AS INT) BETWEEN 201701 AND 202112
GROUP BY 1, 2
UNION ALL
SELECT 'e_perm.t_fact_report_rcc_rsk',
       SUBSTR(CAST(codmes AS VARCHAR), 1, 4),
       COUNT(*), COUNT(DISTINCT CAST(codmes AS VARCHAR)),
       MIN(CAST(codmes AS VARCHAR)), MAX(CAST(codmes AS VARCHAR))
FROM e_perm_aws.t_fact_report_rcc_rsk
WHERE CAST(codmes AS INT) BETWEEN 201701 AND 202112
GROUP BY 1, 2
ORDER BY 1, 2
