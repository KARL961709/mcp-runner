-- m05_arranque_dperm.sql | 2014 y 2015 vinieron vacios y 201705 tiene datos: en que mes arranca de verdad d_perm
SELECT p_codmes,
       count(1)                  AS filas,
       count(DISTINCT key_value) AS clientes
FROM d_perm_aws.t_fact_report_rcc_rsk
WHERE p_codmes BETWEEN '201601' AND '201712'
GROUP BY p_codmes
ORDER BY p_codmes
