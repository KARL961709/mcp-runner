-- cobertura tbl_rcc_per_allsf_mdl: filas por codmes (202605-202608). codmes es varchar.
SELECT CAST(codmes AS varchar) AS codmes, COUNT(*) AS n
FROM e_perm_aws.tbl_rcc_per_allsf_mdl
WHERE CAST(codmes AS varchar) BETWEEN '202605' AND '202608'
GROUP BY CAST(codmes AS varchar)
ORDER BY 1
