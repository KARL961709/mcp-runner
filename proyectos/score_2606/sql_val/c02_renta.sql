-- cobertura ds_rtd_rskvol_cas_ingr_ir: filas por periodo (202605-202608). Confirma si llega a 202608.
SELECT CAST(periodo AS varchar) AS codmes, COUNT(*) AS n
FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
WHERE periodo BETWEEN '202605' AND '202608'
GROUP BY CAST(periodo AS varchar)
ORDER BY 1
