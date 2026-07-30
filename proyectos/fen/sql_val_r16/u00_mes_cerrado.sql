-- u00 ESTA CERRADO 202607? -- si cae respecto de 202606, el mes esta a medio cargar
SELECT 'stock' AS tabla, p_codmes, count(*) AS n_filas, count(DISTINCT key_value) AS n_personas
FROM e_perm_aws.scr_vcclibnk_rsk WHERE p_codmes >= '202604' GROUP BY 1, 2
UNION ALL
SELECT 'admision', p_codmes, count(*), count(DISTINCT key_value)
FROM d_perm_aws.scr_vcadmbnk_hist_rsk WHERE p_codmes >= '202604' GROUP BY 1, 2
ORDER BY 1, 2
