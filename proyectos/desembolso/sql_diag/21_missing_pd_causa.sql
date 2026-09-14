-- 21_missing_pd_causa.sql | para las filas sin pd_raw (sin_pd=1) de b46029_desemb_base_202609, separa la causa: el cliente NO tiene ningun score BPE en scr_admbankbpe_rsk (canal distinto, esperado) vs SI tiene score pero solo con score_codmes DESPUES del desembolso (el as-of lo excluye, seria arreglable). score_codmes = p_codmes + 1 (offset +1). Devuelve conteos y quiebre por producto y personeria. READ-ONLY
WITH miss AS (
  SELECT cod_mes, cod_tip_doc, key_value, desc_producto, desc_cliente
  FROM disc_model_owner.b46029_desemb_base_202609
  WHERE sin_pd = 1
),
scr AS (
  SELECT cast(tip_doc AS varchar) AS td, key_value AS kv,
    cast(date_format(date_parse(cast(p_codmes AS varchar), '%Y%m') + interval '1' month, '%Y%m') AS int) AS score_codmes
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE probabilidad IS NOT NULL AND p_codmes BETWEEN '202001' AND '202609'
),
j AS (
  SELECT m.cod_mes, m.desc_producto, m.desc_cliente,
    max(CASE WHEN s.kv IS NOT NULL THEN 1 ELSE 0 END) AS tiene_score,
    max(CASE WHEN s.score_codmes <= m.cod_mes THEN 1 ELSE 0 END) AS tiene_asof
  FROM miss m
  LEFT JOIN scr s ON s.td = m.cod_tip_doc AND s.kv = m.key_value
  GROUP BY m.cod_mes, m.cod_tip_doc, m.key_value, m.desc_producto, m.desc_cliente
)
SELECT desc_producto, desc_cliente,
  count(*) AS missing_rows,
  sum(CASE WHEN tiene_score = 0 THEN 1 ELSE 0 END) AS sin_ningun_score_bpe,
  sum(CASE WHEN tiene_score = 1 AND tiene_asof = 0 THEN 1 ELSE 0 END) AS score_solo_despues,
  sum(CASE WHEN tiene_asof = 1 THEN 1 ELSE 0 END) AS revisar_deberia_matchear
FROM j
GROUP BY desc_producto, desc_cliente
ORDER BY missing_rows DESC
