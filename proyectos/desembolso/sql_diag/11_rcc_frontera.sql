-- 11_rcc_frontera.sql | frontera real de la RCC (e_perm_aws.t_fact_report_rcc_rsk): volumen por codmes en los ultimos meses, para ver hasta que mes la RD esta cerrada. El ultimo mes con volumen normal es la frontera de madurez del target; los meses siguientes (o parciales) no se pueden usar para cerrar el default. READ-ONLY
SELECT cast(codmes AS int) AS codmes, count(*) AS n_rcc
FROM e_perm_aws.t_fact_report_rcc_rsk
WHERE codmes BETWEEN '202412' AND '202612'
GROUP BY cast(codmes AS int)
ORDER BY codmes
