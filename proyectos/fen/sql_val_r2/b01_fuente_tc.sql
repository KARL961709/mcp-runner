-- b01 FUENTE madre stock TC -- ventana medida contando filas, no min/max
SELECT p_codmes, count(*) AS n_filas, count(DISTINCT codmes_mrm) AS n_mrm
FROM e_perm_aws.ds_flg_comportc_rsk
WHERE p_codmes >= '202301'
GROUP BY p_codmes
ORDER BY p_codmes
