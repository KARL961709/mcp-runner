-- diag_scr_2_v2match | cruce 4: cobertura del esc V2 (bankbn) sobre el universo scoreado 202501+, por personeria y por campana. Agregado.
WITH v2 AS (
  SELECT CAST(p_codmes AS INT) AS p_codmes, tip_doc, key_value,
         ROW_NUMBER() OVER (PARTITION BY p_codmes, tip_doc, key_value ORDER BY fec_replica DESC) AS rn
  FROM disc_model_owner.scr_admbankbpe_calibrado_202607
  WHERE p_codmes >= '202501'
),
s AS (
  SELECT CAST(p_codmes AS INT) AS p_codmes, tip_doc, key_value
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE modelo = 'ADMBANKBPE' AND probabilidad IS NOT NULL AND p_codmes >= '202501'
)
SELECT s.p_codmes,
  CASE WHEN s.tip_doc = '2' THEN 'PJ' ELSE 'PN' END AS personeria,
  COUNT(*) AS n_scr,
  SUM(CASE WHEN v2.key_value IS NOT NULL THEN 1 ELSE 0 END) AS n_v2match,
  ROUND(100.0 * SUM(CASE WHEN v2.key_value IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_match
FROM s
LEFT JOIN v2 ON v2.tip_doc = s.tip_doc AND v2.key_value = s.key_value AND v2.p_codmes = s.p_codmes AND v2.rn = 1
GROUP BY s.p_codmes, CASE WHEN s.tip_doc = '2' THEN 'PJ' ELSE 'PN' END
ORDER BY s.p_codmes, personeria
