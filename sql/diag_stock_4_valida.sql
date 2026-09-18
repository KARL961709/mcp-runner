-- diag_stock_4_valida | cuadre desc_cliente (desembolsos) vs presencia en STOCK antes del desembolso. Valida la regla RECURRENTE<=>en stock, NUEVO<=>no en stock. Conteos, no data cruda.
-- estado: a_stock_m1 = en stock al mes previo (cod_mes-1) | b_stock_antes = en stock en algun mes anterior | c_stock_solo_desde = primera aparicion en stock >= cod_mes | d_nunca_stock = nunca en stock
WITH sdist AS (
  SELECT DISTINCT CAST(tip_doc AS VARCHAR) AS tip_doc, key_value, CAST(codmes AS INT) AS codmes
  FROM e_perm_aws.scr_cmpbpeibk2_rsk
),
sagg AS (
  SELECT CAST(tip_doc AS VARCHAR) AS tip_doc, key_value, MIN(CAST(codmes AS INT)) AS min_cm
  FROM e_perm_aws.scr_cmpbpeibk2_rsk GROUP BY CAST(tip_doc AS VARCHAR), key_value
),
d AS (
  SELECT cod_mes, cod_tip_doc, key_value, desc_cliente
  FROM disc_model_owner.b46029_desemb_base_202609 WHERE pd_raw IS NOT NULL
)
SELECT d.desc_cliente,
  CASE WHEN m1.key_value IS NOT NULL THEN 'a_stock_m1'
       WHEN sa.min_cm IS NOT NULL AND sa.min_cm < d.cod_mes THEN 'b_stock_antes'
       WHEN sa.min_cm IS NOT NULL THEN 'c_stock_solo_desde'
       ELSE 'd_nunca_stock' END AS estado_stock,
  COUNT(*) AS n
FROM d
LEFT JOIN sdist m1 ON m1.tip_doc=d.cod_tip_doc AND m1.key_value=d.key_value AND m1.codmes=d.cod_mes-1
LEFT JOIN sagg sa ON sa.tip_doc=d.cod_tip_doc AND sa.key_value=d.key_value
GROUP BY d.desc_cliente,
  CASE WHEN m1.key_value IS NOT NULL THEN 'a_stock_m1'
       WHEN sa.min_cm IS NOT NULL AND sa.min_cm < d.cod_mes THEN 'b_stock_antes'
       WHEN sa.min_cm IS NOT NULL THEN 'c_stock_solo_desde'
       ELSE 'd_nunca_stock' END
ORDER BY d.desc_cliente, estado_stock
