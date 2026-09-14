-- 19_bridge_ctaibk_cobertura.sql | prueba si el puente e_perm_aws.t_mst_ctaibk_rsk (cod_cuc <-> key_value) conecta user_desembolso con el RCD. Mide cardinalidad del puente (pares, key_value distintos, cod_cuc distintos, cuc por key para ver fanout) y la cobertura: de los key_value de user_desembolso cuantos tienen cod_cuc en el puente. ASUME que las columnas se llaman key_value y cod_cuc (confirmar con diag 18, si difieren se ajusta). Solo conteos agregados, sin PII. READ-ONLY
WITH b AS (
  SELECT DISTINCT key_value AS kv, cod_cuc AS cuc
  FROM e_perm_aws.t_mst_ctaibk_rsk
  WHERE key_value IS NOT NULL AND cod_cuc IS NOT NULL
),
u AS (
  SELECT DISTINCT key_value AS kv FROM d_perm_aws.user_desembolso
),
bstats AS (
  SELECT cast(count(*) AS bigint) AS pares,
         cast(count(DISTINCT kv) AS bigint) AS keys,
         cast(count(DISTINCT cuc) AS bigint) AS cucs
  FROM b
),
cov AS (
  SELECT cast(count(*) AS bigint) AS u_keys,
         cast(count(CASE WHEN d.kv IS NOT NULL THEN 1 END) AS bigint) AS u_con_cuc
  FROM u LEFT JOIN (SELECT DISTINCT kv FROM b) d ON d.kv = u.kv
)
SELECT c.u_keys, c.u_con_cuc,
       round(100.0 * c.u_con_cuc / nullif(c.u_keys, 0), 2) AS pct_bridge,
       s.pares AS puente_pares, s.keys AS puente_keys, s.cucs AS puente_cucs,
       round(1.0 * s.pares / nullif(s.keys, 0), 3) AS cuc_por_key
FROM cov c CROSS JOIN bstats s
