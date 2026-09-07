-- cobertura t_fact_report_rcc_rsk: filas por codmes (202605-202608). Confirma si llega a 202608.
SELECT CAST(codmes AS varchar) AS codmes, COUNT(*) AS n
FROM e_perm_aws.t_fact_report_rcc_rsk
WHERE codmes BETWEEN 202605 AND 202608
GROUP BY CAST(codmes AS varchar)
ORDER BY 1
