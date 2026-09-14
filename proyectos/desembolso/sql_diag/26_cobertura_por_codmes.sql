-- 26_cobertura_por_codmes.sql | cobertura del cruce usando codmes (mes de NEGOCIO), no p_codmes (particion). Para el universo de user_desembolso, por personeria, mide cuantos clientes-mes tienen score con codmes = cod_mes (misma campana de negocio) y cuantos tienen algun score. Si pct_codmes_eq sube a ~99% en NUEVO y RECURRENTE, el cruce correcto es codmes = cod_mes. Solo conteos. READ-ONLY
WITH u AS (
  SELECT DISTINCT cast(cod_mes AS int) AS cm, cod_tip_doc AS td, key_value AS kv, desc_cliente AS dc
  FROM d_perm_aws.user_desembolso
),
scr AS (
  SELECT DISTINCT cast(tip_doc AS varchar) AS td, key_value AS kv, cast(codmes AS int) AS cmes
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE probabilidad IS NOT NULL
),
j AS (
  SELECT u.cm, u.dc, u.td, u.kv,
    max(CASE WHEN s.cmes = u.cm THEN 1 ELSE 0 END) AS hit_eq,
    max(CASE WHEN s.kv IS NOT NULL THEN 1 ELSE 0 END) AS hit_any
  FROM u
  LEFT JOIN scr s ON s.td = u.td AND s.kv = u.kv
  GROUP BY u.cm, u.dc, u.td, u.kv
)
SELECT dc AS desc_cliente,
  count(*) AS clientes_mes,
  sum(hit_eq) AS con_score_codmes_eq,
  round(100.0 * sum(hit_eq) / count(*), 1) AS pct_codmes_eq,
  sum(hit_any) AS con_algun_score,
  round(100.0 * sum(hit_any) / count(*), 1) AS pct_any
FROM j
GROUP BY dc
ORDER BY dc
