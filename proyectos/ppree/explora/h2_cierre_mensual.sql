-- ============================================================================
-- H2. A13 - t_rsk_bkp_cierre_mensual: aporta dm/vig/ven/jud/castigado (target y
--     4 de las 6 ramas duras). Necesaria de 201901 a 202212 (T0+12).
-- ============================================================================
SELECT
  SUBSTR(CAST(codmes AS VARCHAR), 1, 4)                                                     AS anio,
  COUNT(*)                                                                                  AS n,
  COUNT(DISTINCT CAST(codmes AS VARCHAR))                                                   AS n_meses_con_filas,
  MIN(CAST(codmes AS VARCHAR))                                                              AS mes_min,
  MAX(CAST(codmes AS VARCHAR))                                                              AS mes_max,
  SUM(CASE WHEN prod LIKE '06%' AND (subprod IS NULL OR subprod <> 'Cre.Efec.GH') AND aplicativo = 'HPC' THEN 1 ELSE 0 END) AS n_pp_hpc,
  SUM(CASE WHEN prod = '06 Cred efectivo' AND subprod = 'Cre.Efec.GH' THEN 1 ELSE 0 END)    AS n_gtia_hip,
  SUM(CASE WHEN prod LIKE '08%' AND subprod LIKE '06%' AND aplicativo = 'HPC' THEN 1 ELSE 0 END) AS n_refi,
  SUM(CASE WHEN dm IS NULL THEN 1 ELSE 0 END)                                               AS n_dm_null,
  SUM(CASE WHEN as_of_date IS NULL THEN 1 ELSE 0 END)                                       AS n_asof_null
FROM e_perm_aws.t_rsk_bkp_cierre_mensual
WHERE CAST(codmes AS INT) BETWEEN 201901 AND 202212
GROUP BY 1
ORDER BY 1
