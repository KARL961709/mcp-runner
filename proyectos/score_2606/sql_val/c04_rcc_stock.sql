-- cobertura t_rsk_rcc_stock: filas por codmes (202605-202608). codmes es varchar.
SELECT CAST(codmes AS varchar) AS codmes, COUNT(*) AS n
FROM e_perm_aws.t_rsk_rcc_stock
WHERE CAST(codmes AS varchar) BETWEEN '202605' AND '202608'
GROUP BY CAST(codmes AS varchar)
ORDER BY 1
