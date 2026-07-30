-- g04 DOMINIO DE tip_doc en los dos lados del join -- formato medido antes de cruzar
SELECT 'dim_cliente' AS fuente, tipo_identificacion_host AS tip_doc, count(*) AS n
FROM e_perm_aws.t_dim_cliente
GROUP BY 1, 2
UNION ALL
SELECT 'stock_vccli', cod_tip_doc, count(*)
FROM e_perm_aws.scr_vcclibnk_rsk
WHERE p_codmes = '202607'
GROUP BY 1, 2
ORDER BY 1, 3 DESC
LIMIT 40
