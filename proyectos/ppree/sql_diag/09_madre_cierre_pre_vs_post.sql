-- ============================================================================
-- 09. FUENTE MADRE: FOTO PP DEL CLIENTE AL CIERRE D-1 vs CIERRE D (MES DE DESEMBOLSO)
-- ============================================================================
WITH mar AS (
  SELECT DISTINCT
    CAST(b.key_value AS VARCHAR)         AS key_value,
    CAST(a.codmes_desembolso AS VARCHAR) AS d
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp a
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
    ON CAST(a.cif_key AS VARCHAR) = CAST(b.cod_cuc AS VARCHAR)
  WHERE a.subproducto = '1.REENGANCHE'
    AND LENGTH(CAST(b.key_value AS VARCHAR)) = 64
    AND CAST(a.codmes_desembolso AS VARCHAR) BETWEEN '202401' AND '202606'
),
c AS (
  SELECT
    CAST(codmes AS VARCHAR)                                              AS codmes,
    CAST(key_value AS VARCHAR)                                           AS key_value,
    COUNT(*)                                                             AS n_ctas,
    MAX(dm)                                                              AS dm_max,
    SUM(COALESCE(CAST(deuda_vig_sol AS DOUBLE), 0)
      + COALESCE(CAST(deuda_ven_sol AS DOUBLE), 0)
      + COALESCE(CAST(deuda_jud_sol AS DOUBLE), 0))                      AS saldo_sol
  FROM e_perm_aws.t_rsk_bkp_cierre_mensual
  WHERE CAST(codmes AS INT) BETWEEN 202312 AND 202606
    AND prod LIKE '06%' AND (subprod IS NULL OR subprod <> 'Cre.Efec.GH') AND aplicativo = 'HPC'
  GROUP BY 1, 2
),
j AS (
  SELECT SUBSTR(m.d, 1, 4) AS anio,
         c0.n_ctas AS n_pre,  c0.saldo_sol AS s_pre,  c0.dm_max AS dm_pre,
         c1.n_ctas AS n_post, c1.saldo_sol AS s_post, c1.dm_max AS dm_post
  FROM mar m
  LEFT JOIN c c0 ON c0.key_value = m.key_value
               AND c0.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(m.d, '%Y%m')), '%Y%m')
  LEFT JOIN c c1 ON c1.key_value = m.key_value
               AND c1.codmes = m.d
)
SELECT
  COALESCE(anio, 'TOTAL')                                                    AS anio,
  COUNT(*)                                                                   AS n_altas,
  ROUND(AVG(CASE WHEN n_pre  IS NOT NULL THEN 1.0 ELSE 0 END), 4)            AS pct_con_pp_cierre_d_1,
  ROUND(AVG(CASE WHEN n_post IS NOT NULL THEN 1.0 ELSE 0 END), 4)            AS pct_con_pp_cierre_d,
  ROUND(AVG(n_pre), 3)                                                       AS n_ctas_media_pre,
  ROUND(AVG(n_post), 3)                                                      AS n_ctas_media_post,
  ROUND(APPROX_PERCENTILE(s_pre, 0.5), 0)                                    AS saldo_mediano_pre,
  ROUND(APPROX_PERCENTILE(s_post, 0.5), 0)                                   AS saldo_mediano_post,
  ROUND(APPROX_PERCENTILE(s_post / NULLIF(s_pre, 0), 0.5), 3)                AS ratio_saldo_mediano,
  ROUND(AVG(CASE WHEN s_pre > 0 AND s_post IS NOT NULL
                 THEN CASE WHEN s_post > 1.1 * s_pre THEN 1.0 ELSE 0 END END), 4) AS pct_saldo_sube_10pct,
  ROUND(AVG(CASE WHEN dm_pre  > 0  THEN 1.0 WHEN dm_pre  IS NOT NULL THEN 0 END), 4) AS pct_mora_pre,
  ROUND(AVG(CASE WHEN dm_post > 0  THEN 1.0 WHEN dm_post IS NOT NULL THEN 0 END), 4) AS pct_mora_post,
  ROUND(AVG(CASE WHEN dm_pre  > 30 THEN 1.0 WHEN dm_pre  IS NOT NULL THEN 0 END), 4) AS pct_mora30_pre,
  ROUND(AVG(CASE WHEN dm_pre  > 60 THEN 1.0 WHEN dm_pre  IS NOT NULL THEN 0 END), 4) AS pct_mora60_pre,
  ROUND(AVG(CASE WHEN dm_post > 60 THEN 1.0 WHEN dm_post IS NOT NULL THEN 0 END), 4) AS pct_mora60_post
FROM j
GROUP BY GROUPING SETS ((anio), ())
ORDER BY 1
