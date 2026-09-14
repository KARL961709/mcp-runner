-- 27_ejemplos_codmes.sql | EJEMPLOS reales para VER la relacion codmes vs p_codmes vs el mes del desembolso. Toma clientes NUEVO desembolsados en 202605 (los que hoy salen missing), une a scr_admbankbpe_rsk por (tip_doc, key_value) SIN filtro de mes, y muestra sus filas de score: codmes de negocio, p_codmes particion, probabilidad, modelo, segmento, y las diferencias en meses YYYYMM. Llave truncada a 12 chars. Limite 25 filas. READ-ONLY
WITH sample AS (
  SELECT cast(cod_mes AS int) AS cm, cod_tip_doc AS td, key_value AS kv, desc_producto
  FROM d_perm_aws.user_desembolso
  WHERE cod_mes = 202605 AND desc_cliente = 'NUEVO'
  ORDER BY key_value
  LIMIT 8
),
scr AS (
  SELECT cast(tip_doc AS varchar) AS td, key_value AS kv,
         cast(codmes AS int) AS codmes, cast(p_codmes AS int) AS p_codmes,
         probabilidad, modelo, segmento
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE probabilidad IS NOT NULL
)
SELECT substr(sm.kv, 1, 12) AS kv12, sm.desc_producto,
  sm.cm AS desemb_cod_mes,
  s.codmes AS scr_codmes, s.p_codmes AS scr_p_codmes,
  (s.codmes - sm.cm) AS dif_codmes_vs_desemb,
  (s.p_codmes - s.codmes) AS dif_pcod_vs_codmes,
  s.probabilidad, s.modelo, s.segmento
FROM sample sm
LEFT JOIN scr s ON s.td = sm.td AND s.kv = sm.kv
ORDER BY sm.kv, s.codmes
LIMIT 25
