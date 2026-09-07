-- cobertura t_fact_rsk_cuenta_sueldo: filas por cod_mes (202605-202608). Confirma si llega a 202608.
SELECT CAST(cod_mes AS varchar) AS codmes, COUNT(*) AS n
FROM e_perm_aws.t_fact_rsk_cuenta_sueldo
WHERE cod_mes BETWEEN '202605' AND '202608'
GROUP BY CAST(cod_mes AS varchar)
ORDER BY 1
