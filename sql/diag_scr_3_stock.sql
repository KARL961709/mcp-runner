-- diag_scr_3_stock | cruce 1: desc_cliente derivado del stock sobre el universo scoreado 202501+ (RECURRENTE si en stock a codmes<p_codmes). Split y cobertura. Agregado.
WITH sagg AS (
  SELECT tip_doc, key_value, MIN(CAST(codmes AS INT)) AS min_cm
  FROM e_perm_aws.scr_cmpbpeibk2_rsk GROUP BY tip_doc, key_value
),
s AS (
  SELECT DISTINCT CAST(p_codmes AS INT) AS p_codmes, tip_doc, key_value
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE modelo = 'ADMBANKBPE' AND probabilidad IS NOT NULL AND p_codmes >= '202501'
)
SELECT CASE WHEN s.tip_doc = '2' THEN 'PJ' ELSE 'PN' END AS personeria,
  CASE WHEN sa.min_cm IS NOT NULL AND sa.min_cm < s.p_codmes THEN 'RECURRENTE' ELSE 'NUEVO' END AS desc_cliente_der,
  COUNT(*) AS n
FROM s
LEFT JOIN sagg sa ON sa.tip_doc = s.tip_doc AND sa.key_value = s.key_value
GROUP BY CASE WHEN s.tip_doc = '2' THEN 'PJ' ELSE 'PN' END,
  CASE WHEN sa.min_cm IS NOT NULL AND sa.min_cm < s.p_codmes THEN 'RECURRENTE' ELSE 'NUEVO' END
ORDER BY personeria, desc_cliente_der
