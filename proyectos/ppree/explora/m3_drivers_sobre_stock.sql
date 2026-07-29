-- m3  cobertura de los drivers SOBRE LA POBLACION QUE SE VA A PUNTUAR
-- No basta con que la fuente exista: hay que medir que fraccion del stock
-- resuelve tipo_ingreso_dep en cada mes. Lo que no resuelve queda sin segmento
-- y no se puede aplicar el calibrador correspondiente.
SELECT v.codmes,
       COUNT(*)                                                          AS n_stock,
       SUM(CASE WHEN s.key_value IS NOT NULL THEN 1 ELSE 0 END)          AS n_con_sitlab,
       SUM(CASE WHEN c.key_value IS NOT NULL THEN 1 ELSE 0 END)          AS n_con_ctasueldo,
       CAST(ROUND(100.0 * SUM(CASE WHEN s.key_value IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS VARCHAR) AS pct_sitlab
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4 v
LEFT JOIN (SELECT DISTINCT key_value, CAST(periodo AS VARCHAR) AS mes
           FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir) s
       ON CAST(v.key_value AS VARCHAR) = CAST(s.key_value AS VARCHAR)
      AND s.mes = CAST(CAST(v.codmes AS INTEGER) - 1 AS VARCHAR)
LEFT JOIN (SELECT DISTINCT key_value, CAST(codmes AS VARCHAR) AS mes
           FROM e_perm_aws.t_rsk_cta_sueldo) c
       ON CAST(v.key_value AS VARCHAR) = CAST(c.key_value AS VARCHAR)
      AND c.mes = CAST(CAST(v.codmes AS INTEGER) - 1 AS VARCHAR)
WHERE CAST(v.codmes AS VARCHAR) >= '202601'
GROUP BY v.codmes
ORDER BY 1
