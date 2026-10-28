-- ============================================================================
-- 07. COBERTURA, EC Y GINI POR PERIODO Y SEGMENTO: PD_MES vs PD_DESFASE
-- ============================================================================
WITH g AS (
  SELECT codmes_mrm, tip_doc, id_value, target_12m_60 AS y, tipo_ingreso_dep AS seg,
         CASE WHEN codmes_mrm <= '202406' THEN '2024S1'
              WHEN codmes_mrm <= '202412' THEN '2024S2'
              ELSE '2025S1' END AS per
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE flg_scope_ree = 1 AND flg_clean = 1 AND flg_calib = 1
    AND target_12m_60 IS NOT NULL
    AND codmes_mrm BETWEEN '202401' AND '202506'
),
s AS (
  SELECT CAST(codmes AS VARCHAR) AS codmes, CAST(tip_doc AS VARCHAR) AS tip_doc,
         CAST(key_value AS VARCHAR) AS key_value, prob_modelo_cal AS pd
  FROM d_perm_aws.scr_stk_ree_pp_cal_202607
  WHERE CAST(codmes AS VARCHAR) BETWEEN '202401' AND '202507'
),
u AS (
  SELECT '1_pd_mes' AS version, g.per, g.seg, g.y, s.pd
  FROM g
  LEFT JOIN s ON s.codmes = g.codmes_mrm
             AND s.tip_doc = g.tip_doc AND s.key_value = g.id_value
  UNION ALL
  SELECT '2_pd_desfase' AS version, g.per, g.seg, g.y, s.pd
  FROM g
  LEFT JOIN s ON s.codmes = DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(g.codmes_mrm, '%Y%m')), '%Y%m')
             AND s.tip_doc = g.tip_doc AND s.key_value = g.id_value
),
k AS (
  SELECT version, '1_periodo' AS eje, per AS celda, y, pd FROM u
  UNION ALL
  SELECT version, '2_segmento' AS eje, seg AS celda, y, pd FROM u
  UNION ALL
  SELECT version, '3_total' AS eje, 'TOTAL' AS celda, y, pd FROM u
),
r AS (
  SELECT k.*,
         CASE WHEN pd IS NOT NULL
              THEN ROW_NUMBER() OVER (PARTITION BY version, eje, celda ORDER BY pd ASC NULLS LAST)
         END AS rk
  FROM k
)
SELECT
  eje,
  celda,
  version,
  COUNT(*)                                                                    AS n_altas,
  ROUND(AVG(CASE WHEN pd IS NOT NULL THEN 1.0 ELSE 0 END), 4)                 AS pct_cruce,
  SUM(CASE WHEN pd IS NOT NULL THEN y END)                                    AS n_def,
  ROUND(AVG(pd), 4)                                                           AS pd_media,
  ROUND(AVG(CASE WHEN pd IS NOT NULL THEN y END), 4)                          AS rd12,
  ROUND(AVG(pd) / NULLIF(AVG(CASE WHEN pd IS NOT NULL THEN y END), 0) - 1, 4) AS ec,
  ROUND(2 * ((SUM(rk * y) - SUM(CASE WHEN pd IS NOT NULL THEN y END)
                          * (SUM(CASE WHEN pd IS NOT NULL THEN y END) + 1) / 2.0)
             / (SUM(CASE WHEN pd IS NOT NULL THEN y END)
                * (COUNT(pd) - SUM(CASE WHEN pd IS NOT NULL THEN y END)) * 1.0)) - 1, 4) AS gini
FROM r
GROUP BY eje, celda, version
ORDER BY eje, celda, version
