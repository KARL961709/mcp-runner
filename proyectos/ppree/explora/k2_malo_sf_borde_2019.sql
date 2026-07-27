-- ============================================================================
-- K2. H52 - la cohorte t0=201901 lee RCC en 201812, que SOLO existe en d_perm.
--     J2 leyo solo e_perm y dejo 973 sin contraparte. Aqui con el UNION.
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
  SELECT codmes, key_value, condicion FROM d_perm_aws.t_fact_report_rcc_rsk
  WHERE CAST(codmes AS INT) BETWEEN 201812 AND 201812
  UNION ALL
  SELECT codmes, key_value, condicion FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE CAST(codmes AS INT) BETWEEN 201901 AND 201911
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
