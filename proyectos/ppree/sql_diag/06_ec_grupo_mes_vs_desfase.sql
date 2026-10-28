-- ============================================================================
-- 06. EC POR GRUPO: PD_MES (archivo D) vs PD_DESFASE (archivo D+1)
-- ============================================================================
WITH g AS (
  SELECT codmes_mrm, tip_doc, id_value, target_12m_60 AS y
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE flg_scope_ree = 1 AND flg_clean = 1 AND flg_calib = 1
    AND target_12m_60 IS NOT NULL
    AND codmes_mrm BETWEEN '202401' AND '202506'
),
s AS (
  SELECT CAST(codmes AS VARCHAR) AS codmes, CAST(tip_doc AS VARCHAR) AS tip_doc,
         CAST(key_value AS VARCHAR) AS key_value,
         prob_modelo_cal AS pd, puntuacion_cal AS pt
  FROM d_perm_aws.scr_stk_ree_pp_cal_202607
  WHERE CAST(codmes AS VARCHAR) BETWEEN '202401' AND '202507'
),
u AS (
  SELECT '1_pd_mes' AS version, g.y, s.pd, s.pt
  FROM g
  JOIN s ON s.codmes = g.codmes_mrm
        AND s.tip_doc = g.tip_doc AND s.key_value = g.id_value
  UNION ALL
  SELECT '2_pd_desfase' AS version, g.y, s.pd, s.pt
  FROM g
  JOIN s ON s.codmes = DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(g.codmes_mrm, '%Y%m')), '%Y%m')
        AND s.tip_doc = g.tip_doc AND s.key_value = g.id_value
),
c AS (
  SELECT version, y, pd,
         CASE WHEN pt >= 997 THEN 'G1'
              WHEN pt >= 987 THEN 'G2'
              WHEN pt >= 975 THEN 'G3'
              WHEN pt >= 944 THEN 'G4'
              WHEN pt >= 924 THEN 'G5'
              WHEN pt >= 850 THEN 'G6'
              ELSE 'R' END AS grupo
  FROM u
)
SELECT
  version,
  COALESCE(grupo, 'TOTAL')                              AS grupo,
  COUNT(*)                                              AS n,
  SUM(y)                                                AS n_def,
  ROUND(AVG(pd), 4)                                     AS pd_media,
  ROUND(AVG(y), 4)                                      AS rd12,
  ROUND(AVG(pd) / NULLIF(AVG(y), 0) - 1, 4)             AS ec
FROM c
GROUP BY GROUPING SETS ((version, grupo), (version))
ORDER BY 1, 2
