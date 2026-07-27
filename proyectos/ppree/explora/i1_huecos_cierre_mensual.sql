-- ============================================================================
-- I1. h2 devolvio 11 meses en 2021: identificar el hueco en toda la ventana.
--     Un hueco en el cierre mensual infla missing_Nm y fabrica INSUFICIENTE.
-- ============================================================================
SELECT
  SUBSTR(CAST(codmes AS VARCHAR), 1, 4)                                                    AS anio,
  COUNT(DISTINCT CAST(codmes AS VARCHAR))                                                  AS n_meses,
  ARRAY_JOIN(ARRAY_SORT(ARRAY_AGG(DISTINCT SUBSTR(CAST(codmes AS VARCHAR), 5, 2))), ',')   AS meses_presentes,
  MIN(CAST(codmes AS VARCHAR))                                                             AS mes_min,
  MAX(CAST(codmes AS VARCHAR))                                                             AS mes_max
FROM e_perm_aws.t_rsk_bkp_cierre_mensual
WHERE CAST(codmes AS INT) BETWEEN 201901 AND 202606
GROUP BY 1
ORDER BY 1
