-- 32_ejemplos_202608.sql | EJEMPLOS: clientes desembolsados en 202608 y sus filas de score ADMBANKBPE desde codmes 202604, para VER que su score de aprobacion existe pero es de un mes anterior (el mas reciente es 202607 julio, no hay 202608). Confirma que el as-of codmes <= cod_mes recupera su pd_raw con julio. Llave truncada a 12 chars. Limite 30 filas. READ-ONLY
WITH sample AS (
  SELECT cod_tip_doc AS td, key_value AS kv, desc_producto, desc_cliente
  FROM d_perm_aws.user_desembolso
  WHERE cod_mes = 202608
  ORDER BY key_value
  LIMIT 6
),
scr AS (
  SELECT cast(tip_doc AS varchar) AS td, key_value AS kv, cast(codmes AS int) AS codmes, probabilidad
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE probabilidad IS NOT NULL AND modelo = 'ADMBANKBPE' AND codmes >= '202604'
)
SELECT substr(sm.kv, 1, 12) AS kv12, sm.desc_producto, sm.desc_cliente,
  s.codmes AS scr_codmes, s.probabilidad
FROM sample sm
LEFT JOIN scr s ON s.td = sm.td AND s.kv = sm.kv
ORDER BY sm.kv, s.codmes
LIMIT 30
