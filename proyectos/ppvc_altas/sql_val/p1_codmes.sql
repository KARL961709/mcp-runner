-- p1 | Meses reales en la madre raw (formato + frescura). READ-ONLY.
--   Si el max < 202606 -> no esta fresca a jun/jul (hay que buscar otra fuente).
--   Si aparece 202606/202607 con otro formato -> era tema de formato de codmes.
SELECT cast(codmes_desembolso AS varchar) AS codmes, count(*) AS n
FROM disc_monitorian.t_mrm_mongest_altas_pp_marcas
GROUP BY cast(codmes_desembolso AS varchar)
ORDER BY 1 DESC
LIMIT 18
