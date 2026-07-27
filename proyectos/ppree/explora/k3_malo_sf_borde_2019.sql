-- ============================================================================
-- K3. Reemplaza a K2, que omitio el scope de cuentas del Recibido y midio otro
--     predicado (1873 vs 4 en 2019). Aqui con el scope literal de
--     Query Tabla Flag Comportamental PP Vigente - ENR.sql#L206.
-- ============================================================================
WITH ree AS (
  SELECT DISTINCT CAST(B.key_value AS VARCHAR) AS key_value,
                  CAST(A.codmes_desembolso AS VARCHAR) AS codmes_mrm
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp A
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk B ON A.cif_key = B.cod_cuc
  WHERE A.subproducto = '1.REENGANCHE'
    AND CAST(A.codmes_desembolso AS INT) BETWEEN 201901 AND 201912
),
rcc AS (
  SELECT codmes, key_value, condicion
  FROM d_perm_aws.t_fact_report_rcc_rsk
  WHERE CAST(codmes AS INT) = 201812
    AND SUBSTR(cod_cuenta_rcc, 1, 2) = '14'
    AND SUBSTR(cod_cuenta_rcc, 4, 1) IN ('1', '3', '4', '5', '6')
    AND tipo_credito IN ('01','02','03','04','05','06','07','08','09','10','11','12','13')
  UNION ALL
  SELECT codmes, key_value, condicion
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE CAST(codmes AS INT) BETWEEN 201901 AND 201911
    AND SUBSTR(cod_cuenta_rcc, 1, 2) = '14'
    AND SUBSTR(cod_cuenta_rcc, 4, 1) IN ('1', '3', '4', '5', '6')
    AND tipo_credito IN ('01','02','03','04','05','06','07','08','09','10','11','12','13')
),
sf AS (
  SELECT DATE_FORMAT(DATE_PARSE(codmes, '%Y%m') + INTERVAL '1' MONTH, '%Y%m') AS codmes,
         CAST(key_value AS VARCHAR) AS key_value,
         MAX(CAST(condicion AS DOUBLE)) AS cond_max
  FROM rcc
  GROUP BY 1, 2
)
SELECT
  r.codmes_mrm,
  COUNT(*)                                                        AS n_perimetro,
  SUM(CASE WHEN s.key_value IS NULL THEN 1 ELSE 0 END)            AS n_sin_rcc,
  SUM(CASE WHEN s.cond_max > 60 THEN 1 ELSE 0 END)                AS n_malo_sf,
  SUM(CASE WHEN s.cond_max = 9999 THEN 1 ELSE 0 END)              AS n_centinela
FROM ree r
LEFT JOIN sf s ON s.key_value = r.key_value AND s.codmes = r.codmes_mrm
GROUP BY 1
ORDER BY 1
