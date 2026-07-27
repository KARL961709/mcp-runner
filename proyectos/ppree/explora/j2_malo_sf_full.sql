-- ============================================================================
-- J2. R6 - n y badrate POR ANIO de la rama MALO EN EL SF (la unica que lee RCC).
--     Separada de J1 a proposito: el piloto tardo 32 s con 6 meses de RCC, y
--     escalar a 90 no deja margen. Si esta revienta, J1 igual vuelve.
-- ============================================================================
WITH ree AS (
  SELECT DISTINCT CAST(B.key_value AS VARCHAR) AS key_value,
                  CAST(A.codmes_desembolso AS VARCHAR) AS codmes_mrm
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp A
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk B ON A.cif_key = B.cod_cuc
  WHERE A.subproducto = '1.REENGANCHE'
    AND CAST(A.codmes_desembolso AS INT) BETWEEN 201901 AND 202606
),
sf AS (
  SELECT DATE_FORMAT(DATE_PARSE(codmes, '%Y%m') + INTERVAL '1' MONTH, '%Y%m') AS codmes,
         CAST(key_value AS VARCHAR) AS key_value,
         MAX(CAST(condicion AS DOUBLE)) AS cond_max
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE CAST(codmes AS INT) BETWEEN 201812 AND 202605
    AND SUBSTR(cod_cuenta_rcc, 1, 2) = '14'
    AND SUBSTR(cod_cuenta_rcc, 4, 1) IN ('1', '3', '4', '5', '6')
    AND tipo_credito IN ('01','02','03','04','05','06','07','08','09','10','11','12','13')
  GROUP BY 1, 2
),
mad AS (
  SELECT CAST(codmes_mrm AS VARCHAR) AS codmes_mrm, CAST(id_value AS VARCHAR) AS key_value,
         MAX(CASE WHEN flg_rfnc_12m = 1 OR flg_cstg_12m = 1 OR max_dm_12m > 60 THEN 1 ELSE 0 END) AS y12
  FROM e_perm_aws.ds_flg_compppibk_rsk
  GROUP BY 1, 2
)
SELECT
  SUBSTR(r.codmes_mrm, 1, 4)                                                        AS anio,
  COUNT(*)                                                                          AS n_perimetro,
  SUM(CASE WHEN s.key_value IS NULL THEN 1 ELSE 0 END)                              AS n_sin_rcc,
  SUM(CASE WHEN s.cond_max > 60 THEN 1 ELSE 0 END)                                  AS n_malo_sf,
  SUM(CASE WHEN s.cond_max = 9999 THEN 1 ELSE 0 END)                                AS n_centinela,
  ROUND(AVG(CASE WHEN s.cond_max > 60 THEN CAST(m.y12 AS DOUBLE) END), 4)           AS br_malo_sf,
  ROUND(AVG(CASE WHEN COALESCE(s.cond_max, 0) <= 60 THEN CAST(m.y12 AS DOUBLE) END), 4) AS br_resto
FROM ree r
LEFT JOIN sf  s ON s.key_value = r.key_value AND s.codmes = r.codmes_mrm
LEFT JOIN mad m ON m.key_value = r.key_value AND m.codmes_mrm = r.codmes_mrm
GROUP BY 1
ORDER BY 1
