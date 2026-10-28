-- ============================================================================
-- 08. FUENTE MADRE: PD Y FLG_REENGANCHE DE LA V4 EN ARCHIVO D vs D+1 POR ALTA
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
    AND CAST(a.codmes_desembolso AS VARCHAR) BETWEEN '202401' AND '202604'
),
v AS (
  SELECT CAST(key_value AS VARCHAR) AS key_value, CAST(codmes AS VARCHAR) AS codmes,
         MAX(pd_comppp_reen_itc) AS pd, MAX(CAST(flg_reenganche AS INTEGER)) AS flg
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
  GROUP BY 1, 2
),
j AS (
  SELECT SUBSTR(m.d, 1, 4) AS anio,
         v0.pd AS pd_d,  v0.flg AS flg_d,
         v1.pd AS pd_d1, v1.flg AS flg_d1
  FROM mar m
  LEFT JOIN v v0 ON v0.key_value = m.key_value AND v0.codmes = m.d
  LEFT JOIN v v1 ON v1.key_value = m.key_value
               AND v1.codmes = DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(m.d, '%Y%m')), '%Y%m')
)
SELECT
  COALESCE(anio, 'TOTAL')                                                    AS anio,
  COUNT(*)                                                                   AS n_altas,
  ROUND(AVG(CASE WHEN pd_d  IS NOT NULL THEN 1.0 ELSE 0 END), 4)             AS pct_pd_archivo_d,
  ROUND(AVG(CASE WHEN pd_d1 IS NOT NULL THEN 1.0 ELSE 0 END), 4)             AS pct_pd_archivo_d1,
  ROUND(AVG(CASE WHEN flg_d  = 1 THEN 1.0 ELSE 0 END), 4)                    AS pct_flgree_archivo_d,
  ROUND(AVG(CASE WHEN flg_d1 = 1 THEN 1.0 ELSE 0 END), 4)                    AS pct_flgree_archivo_d1,
  ROUND(AVG(pd_d), 4)                                                        AS pd_media_d,
  ROUND(AVG(pd_d1), 4)                                                       AS pd_media_d1,
  ROUND(CORR(pd_d, pd_d1), 4)                                                AS corr_d_d1,
  ROUND(APPROX_PERCENTILE(pd_d1 / pd_d, 0.5), 4)                             AS ratio_mediano_d1_d,
  ROUND(AVG(CASE WHEN pd_d IS NULL OR pd_d1 IS NULL THEN NULL
                 WHEN pd_d1 < pd_d THEN 1.0 ELSE 0 END), 4)                  AS pct_pd_baja_post
FROM j
GROUP BY GROUPING SETS ((anio), ())
ORDER BY 1
