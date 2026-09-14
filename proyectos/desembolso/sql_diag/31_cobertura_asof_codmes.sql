-- 31_cobertura_asof_codmes.sql | cobertura del cruce as-of hacia atras: para cada desembolso el score mas reciente con codmes <= cod_mes (el score que lo aprobo), nunca codmes > cod_mes (no look-ahead). Por personeria mide la cobertura y el desfase en meses entre cod_mes y el codmes tomado (0 = mismo mes, 1 = campana del mes previo, etc.). Se espera pct_asof ~99% y el grueso en desfase 0, con los 202608 cayendo en desfase 1 (toman julio 202607). Solo conteos. READ-ONLY
WITH u AS (
  SELECT DISTINCT cast(cod_mes AS int) AS cm, cod_tip_doc AS td, key_value AS kv, desc_cliente AS dc
  FROM d_perm_aws.user_desembolso
),
scr AS (
  SELECT DISTINCT cast(tip_doc AS varchar) AS td, key_value AS kv, cast(codmes AS int) AS cmes
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE probabilidad IS NOT NULL AND modelo = 'ADMBANKBPE'
),
asof AS (
  SELECT u.cm, u.dc, u.td, u.kv,
    max(CASE WHEN s.cmes <= u.cm THEN s.cmes END) AS cmes_asof
  FROM u
  LEFT JOIN scr s ON s.td = u.td AND s.kv = u.kv
  GROUP BY u.cm, u.dc, u.td, u.kv
),
o AS (
  SELECT dc, cm, cmes_asof,
    CASE WHEN cmes_asof IS NULL THEN NULL
         ELSE ((cm / 100) * 12 + (cm % 100)) - ((cmes_asof / 100) * 12 + (cmes_asof % 100)) END AS desf
  FROM asof
)
SELECT dc AS desc_cliente,
  count(*) AS clientes_mes,
  sum(CASE WHEN cmes_asof IS NOT NULL THEN 1 ELSE 0 END) AS con_asof,
  round(100.0 * sum(CASE WHEN cmes_asof IS NOT NULL THEN 1 ELSE 0 END) / count(*), 1) AS pct_asof,
  sum(CASE WHEN desf = 0 THEN 1 ELSE 0 END) AS desfase0,
  sum(CASE WHEN desf = 1 THEN 1 ELSE 0 END) AS desfase1,
  sum(CASE WHEN desf = 2 THEN 1 ELSE 0 END) AS desfase2,
  sum(CASE WHEN desf >= 3 THEN 1 ELSE 0 END) AS desfase3plus
FROM o
GROUP BY dc
ORDER BY dc
