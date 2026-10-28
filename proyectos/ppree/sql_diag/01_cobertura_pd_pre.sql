-- ============================================================================
-- 01. COBERTURA Y RELACION PD PRE (archivo D) vs PD POST (archivo D+1)
-- ============================================================================
WITH base AS (
  SELECT codmes_mrm, tip_doc, id_value, pd_raw AS pd_post, target_12m_60 AS y,
         CASE WHEN codmes_mrm <= '202406' THEN '2024S1'
              WHEN codmes_mrm <= '202412' THEN '2024S2'
              ELSE '2025S1' END AS per
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE flg_scope_ree = 1 AND flg_clean = 1 AND flg_calib = 1
    AND target_12m_60 IS NOT NULL
    AND codmes_mrm BETWEEN '202401' AND '202506'
),
v AS (
  SELECT CAST(key_value AS VARCHAR) AS id_value, CAST(cod_tip_doc AS VARCHAR) AS tip_doc,
         CAST(codmes AS VARCHAR) AS codmes, MAX(pd_comppp_reen_itc) AS pd
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
  WHERE CAST(codmes AS VARCHAR) BETWEEN '202312' AND '202507'
  GROUP BY 1, 2, 3
),
j AS (
  SELECT b.*, v0.pd AS pd_pre, v1.pd AS pd_pre2
  FROM base b
  LEFT JOIN v v0 ON v0.id_value = b.id_value AND v0.tip_doc = b.tip_doc
               AND v0.codmes = b.codmes_mrm
  LEFT JOIN v v1 ON v1.id_value = b.id_value AND v1.tip_doc = b.tip_doc
               AND v1.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(b.codmes_mrm, '%Y%m')), '%Y%m')
)
SELECT
  COALESCE(per, 'TOTAL')                                                       AS per,
  COUNT(*)                                                                     AS n,
  ROUND(AVG(y), 4)                                                             AS rd12,
  ROUND(AVG(CASE WHEN pd_pre  IS NOT NULL THEN 1.0 ELSE 0 END), 4)             AS pct_con_pd_pre_d,
  ROUND(AVG(CASE WHEN pd_pre2 IS NOT NULL THEN 1.0 ELSE 0 END), 4)             AS pct_con_pd_pre_dm1,
  ROUND(AVG(pd_post), 4)                                                       AS pd_post_media,
  ROUND(AVG(pd_pre), 4)                                                        AS pd_pre_media,
  ROUND(AVG(pd_pre2), 4)                                                       AS pd_pre_dm1_media,
  ROUND(CORR(pd_post, pd_pre), 4)                                              AS corr_post_pre,
  ROUND(AVG(CASE WHEN pd_pre IS NULL THEN NULL
                 WHEN pd_pre > pd_post THEN 1.0 ELSE 0 END), 4)                AS pct_pre_mayor,
  ROUND(APPROX_PERCENTILE(pd_pre / pd_post, 0.5), 4)                           AS ratio_mediano_pre_post
FROM j
GROUP BY GROUPING SETS ((per), ())
ORDER BY 1
