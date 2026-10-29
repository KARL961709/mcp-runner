-- ============================================================================
-- v25. GRAFIAS de desc_producto_agrupado que el IN del 50_pd podria dejar fuera
--   El filtro es IN ('REENGANCHE', 'Reenganche'): identidad por nombre. Se listan
--   todas las grafias que contienen ENGANCHE con su conteo y su largo en bytes,
--   para ver espacios, tildes y variantes de caja que el IN no cubre.
-- ============================================================================
SELECT
  desc_producto_agrupado                                                  AS grafia,
  LENGTH(desc_producto_agrupado)                                          AS n_chars,
  LENGTH(TO_UTF8(desc_producto_agrupado))                                 AS n_bytes,
  CASE WHEN desc_producto_agrupado IN ('REENGANCHE', 'Reenganche') THEN 1 ELSE 0 END AS la_cubre_el_in,
  COUNT(*)                                                                AS n_filas,
  COUNT(DISTINCT CAST(cod_mes AS VARCHAR))                                AS n_meses,
  MIN(CAST(cod_mes AS VARCHAR))                                           AS mes_min,
  MAX(CAST(cod_mes AS VARCHAR))                                           AS mes_max
FROM e_perm_aws.t_fact_rsk_desembolsos_pp
WHERE UPPER(desc_producto_agrupado) LIKE '%ENGANCHE%'
GROUP BY desc_producto_agrupado,
         LENGTH(desc_producto_agrupado),
         LENGTH(TO_UTF8(desc_producto_agrupado)),
         CASE WHEN desc_producto_agrupado IN ('REENGANCHE', 'Reenganche') THEN 1 ELSE 0 END
ORDER BY 5 DESC
