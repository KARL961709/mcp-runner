-- ============================================================================
-- 05. EC POR GRUPO CON PD_MES (archivo de scoring = mes de venta)
-- ============================================================================
WITH poblacion AS (
  SELECT
    s.prob_modelo_cal AS pd_cal,
    s.puntuacion_cal  AS puntuacion_cal_ppree,
    g.target_12m_60   AS def_flag,
    g.codmes_mrm
  FROM d_perm_aws.scr_stk_ree_pp_cal_202607 s
  JOIN disc_model_owner.ds_stk_ree_pp_cal g
    ON g.codmes_mrm = s.codmes
   AND g.tip_doc    = s.tip_doc
   AND g.id_value   = s.key_value
  WHERE g.codmes_mrm BETWEEN '202401' AND '202506'
    AND g.flg_scope_ree = 1
    AND g.flg_clean     = 1
    AND g.flg_calib     = 1
),
clasificado AS (
  SELECT
    *,
    CASE
      WHEN puntuacion_cal_ppree >= 997 THEN 'G1'
      WHEN puntuacion_cal_ppree >= 987 THEN 'G2'
      WHEN puntuacion_cal_ppree >= 975 THEN 'G3'
      WHEN puntuacion_cal_ppree >= 944 THEN 'G4'
      WHEN puntuacion_cal_ppree >= 924 THEN 'G5'
      WHEN puntuacion_cal_ppree >= 850 THEN 'G6'
      ELSE 'R'
    END AS grupo_cal
  FROM poblacion
)
SELECT
  COALESCE(grupo_cal, 'TOTAL')                                          AS grupo_cal,
  COUNT(*)                                                              AS n,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () * 2, 2)                AS n_pct,
  ROUND(AVG(pd_cal), 4)                                                 AS mean_pd_cal,
  SUM(def_flag)                                                         AS n_def,
  ROUND(SUM(def_flag) * 1.0 / COUNT(*), 4)                              AS rd_obs_12m60,
  ROUND(AVG(pd_cal) / NULLIF(SUM(def_flag) * 1.0 / COUNT(*), 0) - 1, 4) AS ec
FROM clasificado
GROUP BY GROUPING SETS ((grupo_cal), ())
ORDER BY 1
