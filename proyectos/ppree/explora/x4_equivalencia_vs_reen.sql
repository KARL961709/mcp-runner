-- x4  equivalencia contra la tabla vigente en los meses comunes
-- La vigente (..._itc_reen_reprocesov4) alimenta hoy pd_raw. Si la nueva la
-- reproduce en esos meses, extenderla a 202607 es continuidad y no un cambio de fuente
SELECT COALESCE(CAST(n.codmes AS VARCHAR), CAST(r.codmes AS VARCHAR)) AS codmes,
       COUNT(n.key_value)                                  AS n_nueva,
       COUNT(r.key_value)                                  AS n_vigente,
       SUM(CASE WHEN n.key_value IS NOT NULL AND r.key_value IS NOT NULL THEN 1 ELSE 0 END) AS n_comunes
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4 n
FULL OUTER JOIN disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4 r
  ON  CAST(n.key_value AS VARCHAR)   = CAST(r.key_value AS VARCHAR)
  AND CAST(n.cod_tip_doc AS VARCHAR) = CAST(r.cod_tip_doc AS VARCHAR)
  AND CAST(n.codmes AS VARCHAR)      = CAST(r.codmes AS VARCHAR)
GROUP BY COALESCE(CAST(n.codmes AS VARCHAR), CAST(r.codmes AS VARCHAR))
ORDER BY 1 DESC
LIMIT 30
