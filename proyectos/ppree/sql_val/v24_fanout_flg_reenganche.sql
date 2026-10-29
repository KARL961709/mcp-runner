-- ============================================================================
-- v24. FAN-OUT del join de flg_reenganche del 50_pd nuevo
--   El subquery hace SELECT DISTINCT con cod_cif_key pero el ON no lo incluye:
--   un (cod_mes, tip_doc, key_value) con dos cod_cif_key duplica la fila del po.
--   Mide cuantos grupos tienen mas de uno y cuantas filas de mas generan.
-- ============================================================================
WITH d AS (
  SELECT DISTINCT
    CAST(cod_mes AS VARCHAR)     AS cod_mes,
    CAST(tip_doc AS VARCHAR)     AS tip_doc,
    CAST(key_value AS VARCHAR)   AS key_value,
    CAST(cod_cif_key AS VARCHAR) AS cod_cif_key
  FROM e_perm_aws.t_fact_rsk_desembolsos_pp
  WHERE desc_producto_agrupado IN ('REENGANCHE', 'Reenganche')
    AND CAST(cod_mes AS VARCHAR) >= '202401'
),
g AS (
  SELECT cod_mes, tip_doc, key_value, COUNT(*) AS n_cif
  FROM d
  GROUP BY cod_mes, tip_doc, key_value
)
SELECT
  SUBSTR(cod_mes, 1, 4)                                     AS anio,
  COUNT(*)                                                  AS n_grupos,
  SUM(CASE WHEN n_cif > 1 THEN 1 ELSE 0 END)                AS n_grupos_multi_cif,
  ROUND(100.0 * SUM(CASE WHEN n_cif > 1 THEN 1 ELSE 0 END) / COUNT(*), 3) AS pct_multi,
  SUM(n_cif) - COUNT(*)                                     AS filas_extra_que_genera,
  MAX(n_cif)                                                AS max_cif_por_grupo
FROM g
GROUP BY SUBSTR(cod_mes, 1, 4)
ORDER BY 1
