-- cobertura t_agg_retail_user_trx_plin: filas por codmes (202605-202608). Confirma si llega a 202608.
SELECT CAST(codmes AS varchar) AS codmes, COUNT(*) AS n
FROM e_perm_aws.t_agg_retail_user_trx_plin
WHERE codmes BETWEEN 202605 AND 202608
GROUP BY CAST(codmes AS varchar)
ORDER BY 1
