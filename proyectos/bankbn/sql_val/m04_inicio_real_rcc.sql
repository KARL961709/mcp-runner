-- m04_inicio_real_rcc.sql | desde que mes hay filas de verdad en d_perm: 201405 volvio VACIO en m02 y el tramo 1 lee desde ahi
SELECT p_codmes,
       count(1)                  AS filas,
       count(DISTINCT key_value) AS clientes
FROM d_perm_aws.t_fact_report_rcc_rsk
WHERE p_codmes BETWEEN '201401' AND '201512'
GROUP BY p_codmes
ORDER BY p_codmes
