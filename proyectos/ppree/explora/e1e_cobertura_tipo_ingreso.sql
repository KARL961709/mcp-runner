-- ============================================================================
-- E1e. COBERTURA DE ds_rtd_rskvol_cas_ingr_ir POR ANIO  (U6: default silencioso)
-- ============================================================================
SELECT
  SUBSTR(CAST(periodo AS VARCHAR), 1, 4)                        AS anio,
  COUNT(*)                                                      AS n_filas,
  COUNT(DISTINCT CAST(periodo AS VARCHAR))                      AS n_meses_con_filas,
  MIN(CAST(periodo AS VARCHAR))                                 AS mes_min,
  MAX(CAST(periodo AS VARCHAR))                                 AS mes_max,
  SUM(CASE WHEN CAST(numcarga AS INT) = 1 THEN 1 ELSE 0 END)    AS n_carga1,
  COUNT(DISTINCT sit_lab)                                       AS n_dom_sit_lab,
  COUNT(DISTINCT fuente)                                        AS n_dom_fuente
FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
GROUP BY 1
ORDER BY 1
