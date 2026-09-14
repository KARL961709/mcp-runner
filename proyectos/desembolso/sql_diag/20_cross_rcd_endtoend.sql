-- 20_cross_rcd_endtoend.sql | confirma el cruce completo user_desembolso -> puente t_mst_ctaibk_rsk -> RCD t_ifrs_rcddeta_rsk, sobre un mes de RCD (p_codmes 202606). Mide: cuantos cod_cuc del RCD del mes pegan con el puente (prueba formato y cobertura del lado RCD), el largo del cod_cuc del RCD (para detectar ceros a la izquierda o largo distinto), y end-to-end cuantos key_value de user_desembolso aparecen en el RCD de ese mes via puente (cota inferior, es un solo mes). Solo conteos agregados, sin PII. READ-ONLY
WITH br AS (
  SELECT DISTINCT cod_cuc AS cuc, key_value AS kv
  FROM e_perm_aws.t_mst_ctaibk_rsk
  WHERE cod_cuc IS NOT NULL AND key_value IS NOT NULL
),
rcd AS (
  SELECT DISTINCT cod_cuc AS cuc
  FROM e_perm_aws.t_ifrs_rcddeta_rsk
  WHERE p_codmes = '202606' AND cod_cuc IS NOT NULL
),
u AS (
  SELECT DISTINCT key_value AS kv FROM d_perm_aws.user_desembolso
),
j AS (
  SELECT rcd.cuc AS cuc, br.kv AS kv
  FROM rcd LEFT JOIN br ON br.cuc = rcd.cuc
)
SELECT
  cast(count(*) AS bigint) AS rcd_cuc_mes,
  cast(sum(CASE WHEN j.kv IS NOT NULL THEN 1 ELSE 0 END) AS bigint) AS rcd_cuc_en_puente,
  cast(count(DISTINCT CASE WHEN u.kv IS NOT NULL THEN j.kv END) AS bigint) AS u_hallados_rcd_mes,
  cast((SELECT count(*) FROM u) AS bigint) AS u_total,
  cast(min(length(j.cuc)) AS bigint) AS rcd_cuc_len_min,
  cast(max(length(j.cuc)) AS bigint) AS rcd_cuc_len_max
FROM j LEFT JOIN u ON u.kv = j.kv
