-- m03_frontera_rcc_completa.sql | 202606 es un mes COMPLETO de RCC? si viene parcial la frontera de madurez de 12m esta mal
SELECT p_codmes,
       count(1)                  AS filas,
       count(DISTINCT key_value) AS clientes,
       round(sum(saldo), 0)      AS saldo_total
FROM e_perm_aws.t_fact_report_rcc_rsk
WHERE p_codmes BETWEEN '202512' AND '202606'
GROUP BY p_codmes
ORDER BY p_codmes
