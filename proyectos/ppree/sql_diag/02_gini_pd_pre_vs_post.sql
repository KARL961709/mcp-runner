-- ============================================================================
-- 02. RD12 vs PD MEDIA Y GINI: PD POST (D+1) vs PD PRE (D) vs PD PRE (D-1)
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
),
u AS (
  SELECT per,     y, pd_post AS pd, '1_post_D+1' AS version FROM j WHERE pd_pre  IS NOT NULL
  UNION ALL SELECT 'TOTAL', y, pd_post, '1_post_D+1' FROM j WHERE pd_pre  IS NOT NULL
  UNION ALL SELECT per,     y, pd_pre,  '2_pre_D'    FROM j WHERE pd_pre  IS NOT NULL
  UNION ALL SELECT 'TOTAL', y, pd_pre,  '2_pre_D'    FROM j WHERE pd_pre  IS NOT NULL
  UNION ALL SELECT per,     y, pd_pre2, '3_pre_D-1'  FROM j WHERE pd_pre2 IS NOT NULL
  UNION ALL SELECT 'TOTAL', y, pd_pre2, '3_pre_D-1'  FROM j WHERE pd_pre2 IS NOT NULL
),
r AS (
  SELECT per, version, y, pd,
         ROW_NUMBER() OVER (PARTITION BY per, version ORDER BY pd) AS rk
  FROM u
)
SELECT
  per,
  version,
  COUNT(*)                                                                     AS n,
  SUM(y)                                                                       AS n_def,
  ROUND(AVG(y), 4)                                                             AS rd12,
  ROUND(AVG(pd), 4)                                                            AS pd_raw_media,
  ROUND(2 * ((SUM(rk * y) - SUM(y) * (SUM(y) + 1) / 2.0)
             / (SUM(y) * (COUNT(*) - SUM(y)) * 1.0)) - 1, 4)                   AS gini
FROM r
GROUP BY per, version
ORDER BY per, version
