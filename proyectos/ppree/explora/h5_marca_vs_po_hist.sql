-- ============================================================================
-- H5. A13/A14 - Cuanto del perimetro reenganche 2019-2021 tiene contraparte en
--     la PO cruda. Si la marca no cruza, reconstruir la historia no sirve.
-- ============================================================================
WITH ree AS (
  SELECT DISTINCT B.key_value, CAST(A.codmes_desembolso AS VARCHAR) AS codmes_desembolso, B.tip_doc
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp A
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk B ON A.cif_key = B.cod_cuc
  WHERE A.subproducto = '1.REENGANCHE'
    AND CAST(A.codmes_desembolso AS INT) BETWEEN 201901 AND 202112
),
po AS (
  SELECT CAST(codmes AS VARCHAR) AS codmes, CAST(tip_doc AS VARCHAR) AS tip_doc, CAST(key_value AS VARCHAR) AS key_value
  FROM d_perm_aws.ds_compppibk_rsk
  WHERE CAST(codmes AS INT) BETWEEN 201902 AND 202012
  UNION ALL
  SELECT CAST(codmes AS VARCHAR), CAST(tip_doc AS VARCHAR), CAST(key_value AS VARCHAR)
  FROM e_perm_aws.scr_compppibk_rsk
  WHERE CAST(codmes AS INT) BETWEEN 202101 AND 202201
)
SELECT
  SUBSTR(r.codmes_desembolso, 1, 4)                                          AS anio,
  COUNT(*)                                                                   AS n_marca,
  SUM(CASE WHEN p.key_value IS NOT NULL THEN 1 ELSE 0 END)                   AS n_cruza_po,
  ROUND(100.0 * SUM(CASE WHEN p.key_value IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_cruce
FROM ree r
LEFT JOIN po p
  ON CAST(r.key_value AS VARCHAR) = p.key_value
 AND CAST(r.tip_doc AS VARCHAR)   = p.tip_doc
 AND DATE_FORMAT(DATE_PARSE(r.codmes_desembolso, '%Y%m') + INTERVAL '1' MONTH, '%Y%m') = p.codmes
GROUP BY 1
ORDER BY 1
