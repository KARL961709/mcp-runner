-- m06_snapshot_202607.sql | 202607 existe y esta COMPLETO? si viene parcial la frontera de madurez no se mueve
SELECT fuente,
       p_mes                     AS p_codmes,
       count(1)                  AS filas,
       count(DISTINCT key_value) AS clientes,
       round(sum(sld), 0)        AS saldo_total
FROM (
    SELECT 'RCC_e_perm' AS fuente, CAST(p_codmes AS VARCHAR) AS p_mes,
           CAST(key_value AS VARCHAR) AS key_value, TRY_CAST(saldo AS DOUBLE) AS sld
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes BETWEEN '202512' AND '202607'
    UNION ALL
    SELECT 'SCORE', CAST(p_codmes AS VARCHAR),
           CAST(key_value AS VARCHAR), TRY_CAST(probabilidad AS DOUBLE)
    FROM e_perm_aws.scr_admbankbpe_rsk
    WHERE p_codmes BETWEEN '202512' AND '202608'
) u
GROUP BY fuente, p_mes
ORDER BY fuente, p_codmes
