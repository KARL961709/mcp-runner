-- ============================================================================
-- O1. U3 (REABIERTA) - DISPONIBILIDAD DEL CIERRE MENSUAL AL DECIDIR.
--     Cuatro filtros leen esta fuente en t0: malo_origen, mto_pend, baja y
--     gtia_hip. Se dieron por honestos con el argumento de que t0 = ejecucion-1,
--     nunca con una medicion.
--     Test: si la particion del mes M se escribio dentro de M+1, entonces al
--     ejecutar en t0+1 la foto de t0 ya estaba -> honesta. Si se escribio
--     despues, los cuatro son CASO 2 y hay que relaguear.
-- ============================================================================
SELECT
  CAST(codmes AS VARCHAR)                                             AS codmes,
  COUNT(*)                                                            AS n_filas,
  MIN("$file_modified_time" AT TIME ZONE 'America/Lima')              AS carga_min,
  MAX("$file_modified_time" AT TIME ZONE 'America/Lima')              AS carga_max,
  DATE_FORMAT(MAX("$file_modified_time" AT TIME ZONE 'America/Lima'), '%Y%m') AS carga_mes,
  DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(CAST(codmes AS VARCHAR), '%Y%m')), '%Y%m') AS mes_ejecucion,
  CASE WHEN DATE_FORMAT(MAX("$file_modified_time" AT TIME ZONE 'America/Lima'), '%Y%m')
            <= DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(CAST(codmes AS VARCHAR), '%Y%m')), '%Y%m')
       THEN 0 ELSE 1 END                                              AS falla_disponible_al_decidir
FROM e_perm_aws.t_rsk_bkp_cierre_mensual
WHERE CAST(codmes AS INT) BETWEEN 202401 AND 202606
GROUP BY 1
ORDER BY 1
