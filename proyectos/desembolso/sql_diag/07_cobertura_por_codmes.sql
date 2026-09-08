-- 07_cobertura_por_codmes.sql | cobertura as-of vs cliente por cod_mes del desembolso, para ver si el 12% sin pd_raw as-of se concentra en meses tempranos (el scorecard aun no puntuaba, seria recuperable) o es look-ahead disperso (score fechado despues del desembolso, exclusion correcta). solo_post = tiene score pero solo posterior al desembolso. READ-ONLY
WITH ud AS (
  SELECT DISTINCT cast(cod_mes AS int) AS cm, cod_tip_doc AS td, key_value AS kv
  FROM d_perm_aws.user_desembolso
),
scr AS (
  SELECT DISTINCT cast(tip_doc AS varchar) AS td, key_value AS kv, cast(p_codmes AS int) AS pcm
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE probabilidad IS NOT NULL AND p_codmes BETWEEN '202001' AND '202608'
),
j AS (
  SELECT ud.cm, ud.td, ud.kv,
    max(CASE WHEN s.pcm <= ud.cm THEN 1 ELSE 0 END) AS m_asof,
    max(CASE WHEN s.pcm IS NOT NULL THEN 1 ELSE 0 END) AS m_cli
  FROM ud
  LEFT JOIN scr s ON s.td = ud.td AND s.kv = ud.kv
  GROUP BY ud.cm, ud.td, ud.kv
)
SELECT cm AS cod_mes,
  count(*) AS n,
  round(100.0 * avg(m_asof), 1) AS pct_asof,
  round(100.0 * avg(m_cli), 1) AS pct_cliente,
  round(100.0 * avg(CASE WHEN m_cli = 1 AND m_asof = 0 THEN 1 ELSE 0 END), 1) AS pct_solo_post
FROM j
GROUP BY cm
ORDER BY cm
