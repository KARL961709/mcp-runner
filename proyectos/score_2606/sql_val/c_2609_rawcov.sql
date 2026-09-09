-- c_2609_rawcov. Cobertura de meses RECIENTES de las fuentes crudas que un score 202609 necesita.
--   Un 202609 lee lags mas nuevos que el build 2606_2608. Confirmar que cada fuente llegue a su mes critico.
--   rcc_report/rcc_stock/consolidado -> m-2 = 202607 . plin/cuenta_sueldo -> m-1 = 202608 . ingr/renta -> 202609 (sin rezago).
--   Si a una fuente le falta su mes critico, el nodo o el dirty pierde senal en silencio para 202609.
SELECT 'rcc_report' AS src, CAST(codmes AS varchar) AS mes, COUNT(*) AS n
FROM e_perm_aws.t_fact_report_rcc_rsk
WHERE CAST(codmes AS varchar) BETWEEN '202606' AND '202609'
GROUP BY CAST(codmes AS varchar)
UNION ALL
SELECT 'rcc_stock' AS src, CAST(codmes AS varchar) AS mes, COUNT(*) AS n
FROM e_perm_aws.t_rsk_rcc_stock
WHERE CAST(codmes AS varchar) BETWEEN '202606' AND '202609'
GROUP BY CAST(codmes AS varchar)
UNION ALL
SELECT 'plin' AS src, CAST(codmes AS varchar) AS mes, COUNT(*) AS n
FROM e_perm_aws.t_agg_retail_user_trx_plin
WHERE CAST(codmes AS varchar) BETWEEN '202606' AND '202609'
GROUP BY CAST(codmes AS varchar)
UNION ALL
SELECT 'cuenta_sueldo' AS src, CAST(cod_mes AS varchar) AS mes, COUNT(*) AS n
FROM e_perm_aws.t_fact_rsk_cuenta_sueldo
WHERE CAST(cod_mes AS varchar) BETWEEN '202606' AND '202609'
GROUP BY CAST(cod_mes AS varchar)
UNION ALL
SELECT 'ingr' AS src, CAST(periodo AS varchar) AS mes, COUNT(*) AS n
FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
WHERE CAST(periodo AS varchar) BETWEEN '202606' AND '202609'
GROUP BY CAST(periodo AS varchar)
UNION ALL
SELECT 'consolidado' AS src, CAST(cons_periodo AS varchar) AS mes, COUNT(*) AS n
FROM e_perm_aws.t_consolidado_rsk
WHERE CAST(cons_periodo AS varchar) BETWEEN '202606' AND '202609'
GROUP BY CAST(cons_periodo AS varchar)
ORDER BY src, mes
