-- b02 FUENTE madre stock PP -- ventana medida contando filas
SELECT p_codmes, count(*) AS n_filas, count(DISTINCT codmes_mrm) AS n_mrm
FROM e_perm_aws.ds_flg_compppibk_rsk
WHERE p_codmes >= '202201'
GROUP BY p_codmes
ORDER BY p_codmes
