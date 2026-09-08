-- 06_cobertura_scr_raw.sql | cobertura REAL de pd_raw: cruza user_desembolso contra la fuente CRUDA del score e_perm_aws.scr_admbankbpe_rsk (columna probabilidad = pd_raw del scorecard, confirmado en f6_v2native/4b_scoring_v1v2.sql y f3_cal/4b_cal.sql), por producto. exacto = mismo mes (p_codmes = cod_mes), asof = score con p_codmes menor o igual al mes del desembolso (el mas cercano, sin look-ahead), cliente = existe score en cualquier mes. Es el numero correcto, a diferencia del ds_cal que estaba filtrado a altas de calibracion. READ-ONLY
WITH ud AS (
  SELECT DISTINCT cast(cod_mes AS int) AS cm, cod_tip_doc AS td, key_value AS kv, desc_producto AS prod
  FROM d_perm_aws.user_desembolso
),
scr AS (
  SELECT DISTINCT cast(tip_doc AS varchar) AS td, key_value AS kv, cast(p_codmes AS int) AS pcm
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE probabilidad IS NOT NULL AND p_codmes BETWEEN '202101' AND '202608'
),
j AS (
  SELECT ud.prod, ud.cm, ud.td, ud.kv,
    max(CASE WHEN s.pcm = ud.cm THEN 1 ELSE 0 END) AS m_exacto,
    max(CASE WHEN s.pcm <= ud.cm THEN 1 ELSE 0 END) AS m_asof,
    max(CASE WHEN s.pcm IS NOT NULL THEN 1 ELSE 0 END) AS m_cli
  FROM ud
  LEFT JOIN scr s ON s.td = ud.td AND s.kv = ud.kv
  GROUP BY ud.prod, ud.cm, ud.td, ud.kv
)
SELECT prod,
  count(*) AS n,
  round(100.0 * avg(m_exacto), 1) AS pct_exacto,
  round(100.0 * avg(m_asof), 1) AS pct_asof,
  round(100.0 * avg(m_cli), 1) AS pct_cliente
FROM j
GROUP BY prod
ORDER BY n DESC
