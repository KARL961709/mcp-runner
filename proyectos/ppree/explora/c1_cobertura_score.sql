-- c1 | alcance de la tabla de score por mes: hasta donde llega y con que grano
SELECT CAST(codmes AS VARCHAR)                                              AS codmes,
       COUNT(*)                                                             AS n_filas,
       COUNT(DISTINCT key_value)                                            AS n_llaves,
       ROUND(1.0 * COUNT(*) / NULLIF(COUNT(DISTINCT key_value), 0), 3)      AS filas_por_llave,
       SUM(CASE WHEN pd_comppp_reen_itc IS NULL THEN 1 ELSE 0 END)          AS n_pd_nula,
       ROUND(100.0 * AVG(pd_comppp_reen_itc), 4)                            AS pd_raw_pct
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4
GROUP BY CAST(codmes AS VARCHAR)
ORDER BY 1 DESC
LIMIT 30
