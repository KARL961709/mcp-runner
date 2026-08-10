-- m07_snapshot_disponible.sql | que periodos existen hoy en las fuentes particionadas. Decide si el snapshot puede pasar de 202606. Un mes parcial se delata por filas/claves/saldo mas bajos que el anterior
SELECT fuente,
       periodo,
       count(1)                                  AS filas,
       count(DISTINCT key_value)                 AS claves,
       round(sum(medida), 0)                     AS suma_medida,
       round(avg(medida), 4)                     AS media_medida
FROM (
    SELECT 'A_RCC_e_perm'      AS fuente,
           CAST(p_codmes AS VARCHAR)  AS periodo,
           CAST(key_value AS VARCHAR) AS key_value,
           TRY_CAST(saldo AS DOUBLE)  AS medida
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes BETWEEN '202602' AND '202612'
    UNION ALL
    SELECT 'B_RCC_d_perm',
           CAST(p_codmes AS VARCHAR),
           CAST(key_value AS VARCHAR),
           TRY_CAST(saldo AS DOUBLE)
    FROM d_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes BETWEEN '202602' AND '202612'
    UNION ALL
    SELECT 'C_SCORE',
           CAST(p_codmes AS VARCHAR),
           CAST(key_value AS VARCHAR),
           TRY_CAST(probabilidad AS DOUBLE)
    FROM e_perm_aws.scr_admbankbpe_rsk
    WHERE p_codmes BETWEEN '202602' AND '202612'
) u
GROUP BY fuente, periodo
ORDER BY fuente, periodo
