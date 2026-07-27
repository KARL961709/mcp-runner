-- ============================================================================
-- E1b. COBERTURA DE LA MARCA REENGANCHE POR ANIO  (fuente del scope)
-- ============================================================================
SELECT
  SUBSTR(CAST(codmes_desembolso AS VARCHAR), 1, 4)                        AS anio,
  COUNT(*)                                                                AS n_filas,
  COUNT(DISTINCT CAST(codmes_desembolso AS VARCHAR))                      AS n_meses_con_filas,
  MIN(CAST(codmes_desembolso AS VARCHAR))                                 AS mes_min,
  MAX(CAST(codmes_desembolso AS VARCHAR))                                 AS mes_max,
  COUNT(DISTINCT CAST(cif_key AS VARCHAR))                                AS n_cif,
  SUM(CASE WHEN cif_key IS NULL OR CAST(cif_key AS VARCHAR) = '' THEN 1 ELSE 0 END) AS n_cif_nulo,
  COUNT(DISTINCT subproducto)                                             AS n_dom_subproducto
FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp
WHERE subproducto = '1.REENGANCHE'
GROUP BY 1
ORDER BY 1
