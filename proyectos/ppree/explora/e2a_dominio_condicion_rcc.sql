-- ============================================================================
-- E2a. U1 - DOMINIO DE `condicion` EN EL RCC  (sostiene la rama MALO EN EL SF)
--      Test de falsacion escrito ANTES de correr: si `condicion` son dias de
--      atraso, el dominio es entero >= 0 con masa fuerte en 0 y cola < 2000.
-- ============================================================================
SELECT
  codmes,
  typeof(MIN(condicion))                                                   AS t_condicion,
  COUNT(*)                                                                 AS n,
  COUNT(DISTINCT CAST(condicion AS VARCHAR))                               AS n_valores,
  MIN(CAST(condicion AS DOUBLE))                                           AS c_min,
  MAX(CAST(condicion AS DOUBLE))                                           AS c_max,
  SUM(CASE WHEN CAST(condicion AS DOUBLE) = 0 THEN 1 ELSE 0 END)           AS n_cero,
  SUM(CASE WHEN CAST(condicion AS DOUBLE) < 0 THEN 1 ELSE 0 END)           AS n_negativo,
  SUM(CASE WHEN CAST(condicion AS DOUBLE) BETWEEN 1 AND 8 THEN 1 ELSE 0 END)     AS n_1_8,
  SUM(CASE WHEN CAST(condicion AS DOUBLE) BETWEEN 9 AND 30 THEN 1 ELSE 0 END)    AS n_9_30,
  SUM(CASE WHEN CAST(condicion AS DOUBLE) BETWEEN 31 AND 60 THEN 1 ELSE 0 END)   AS n_31_60,
  SUM(CASE WHEN CAST(condicion AS DOUBLE) > 60 THEN 1 ELSE 0 END)                AS n_mayor_60,
  SUM(CASE WHEN CAST(condicion AS DOUBLE) > 2000 THEN 1 ELSE 0 END)              AS n_mayor_2000,
  SUM(CASE WHEN condicion IS NULL THEN 1 ELSE 0 END)                            AS n_null
FROM e_perm_aws.t_fact_report_rcc_rsk
WHERE codmes IN ('202312', '202506')
  AND SUBSTR(cod_cuenta_rcc, 1, 2) = '14'
  AND SUBSTR(cod_cuenta_rcc, 4, 1) IN ('1', '3', '4', '5', '6')
  AND tipo_credito IN ('01','02','03','04','05','06','07','08','09','10','11','12','13')
GROUP BY 1
ORDER BY 1
