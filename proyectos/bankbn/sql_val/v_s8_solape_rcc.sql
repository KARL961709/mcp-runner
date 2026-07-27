-- v_s8_solape_rcc.sql | en un mes del solape, cuanto aporta cada fuente al UNION ALL
SELECT src,
       count(1)                        AS filas,
       count(DISTINCT key_value)       AS clientes,
       sum(saldo)                      AS saldo_total
FROM (
    SELECT 'D_PERM' AS src, key_value, saldo
    FROM d_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '201903'
    UNION ALL
    SELECT 'E_PERM' AS src, key_value, saldo
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '201903'
) u
GROUP BY src
ORDER BY src
