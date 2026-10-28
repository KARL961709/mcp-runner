-- ============================================================================
-- 03. MORA PP AL CIERRE D-1 (pre), AL CIERRE D (post) Y ANTES DEL RE-REENGANCHE
-- ============================================================================
WITH base AS (
  SELECT codmes_mrm, tip_doc, id_value, target_12m_60 AS y
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE flg_scope_ree = 1 AND flg_clean = 1 AND flg_calib = 1
    AND target_12m_60 IS NOT NULL
    AND codmes_mrm BETWEEN '202312' AND '202506'
),
nx AS (
  SELECT b.codmes_mrm, b.tip_doc, b.id_value, MIN(m.codmes_mrm) AS d2
  FROM base b
  INNER JOIN disc_model_owner.ds_stk_ree_pp_11_marca m
          ON m.id_value = b.id_value
         AND m.codmes_mrm > b.codmes_mrm
         AND m.codmes_mrm <= DATE_FORMAT(DATE_ADD('month', 12, DATE_PARSE(b.codmes_mrm, '%Y%m')), '%Y%m')
  GROUP BY 1, 2, 3
),
j AS (
  SELECT b.y, n.d2,
         dpre.dm_max  AS dm_pre,
         dpost.dm_max AS dm_post,
         dre.dm_max   AS dm_antes_re
  FROM base b
  LEFT JOIN nx n
         ON n.codmes_mrm = b.codmes_mrm AND n.tip_doc = b.tip_doc AND n.id_value = b.id_value
  LEFT JOIN disc_model_owner.ds_stk_ree_pp_20_dm dpre
         ON dpre.id_value = b.id_value AND dpre.tip_doc = b.tip_doc
        AND dpre.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(b.codmes_mrm, '%Y%m')), '%Y%m')
  LEFT JOIN disc_model_owner.ds_stk_ree_pp_20_dm dpost
         ON dpost.id_value = b.id_value AND dpost.tip_doc = b.tip_doc
        AND dpost.codmes = b.codmes_mrm
  LEFT JOIN disc_model_owner.ds_stk_ree_pp_20_dm dre
         ON dre.id_value = b.id_value AND dre.tip_doc = b.tip_doc
        AND dre.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(n.d2, '%Y%m')), '%Y%m')
),
u AS (
  SELECT 'a_cierre_D-1_pre'              AS medida, dm_pre      AS dm, y FROM j
  UNION ALL
  SELECT 'b_cierre_D_post'               AS medida, dm_post     AS dm, y FROM j
  UNION ALL
  SELECT 'c_cierre_previo_re-reenganche' AS medida, dm_antes_re AS dm, y FROM j WHERE d2 IS NOT NULL
)
SELECT
  medida,
  CASE WHEN dm IS NULL THEN '0_sin_cuenta_pp'
       WHEN dm = 0     THEN '1_al_dia'
       WHEN dm <= 30   THEN '2_1a30'
       WHEN dm <= 60   THEN '3_31a60'
       ELSE                 '4_mas60' END                                      AS tramo_dm,
  COUNT(*)                                                                     AS n,
  SUM(y)                                                                       AS n_def,
  ROUND(AVG(y), 4)                                                             AS rd12
FROM u
GROUP BY 1, 2
ORDER BY 1, 2
