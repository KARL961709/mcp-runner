-- ============================================================================
-- E1c. VIGENCIA DE t_colaboradores_gdh_rsk  (U8: la rama COLABORADOR se apaga?)
-- ============================================================================
SELECT
  SUBSTR(CAST(periodo_gdh AS VARCHAR), 1, 4)                   AS anio,
  COUNT(*)                                                     AS n_filas,
  COUNT(DISTINCT CAST(periodo_gdh AS VARCHAR))                 AS n_meses_con_filas,
  MIN(CAST(periodo_gdh AS VARCHAR))                            AS mes_min,
  MAX(CAST(periodo_gdh AS VARCHAR))                            AS mes_max,
  SUM(CASE WHEN empresa = 'INTERBANK' THEN 1 ELSE 0 END)       AS n_interbank,
  COUNT(DISTINCT empresa)                                      AS n_dom_empresa
FROM e_perm_aws.t_colaboradores_gdh_rsk
GROUP BY 1
ORDER BY 1
