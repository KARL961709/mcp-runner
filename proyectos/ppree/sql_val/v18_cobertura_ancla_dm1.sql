-- ============================================================================
-- v18. COBERTURA DEL ANCLA D-1 - preflight del export 95
--   Mide exactamente lo que el INNER JOIN del 95 va a conservar y descartar,
--   y la LRA de los dos anclas sobre el MISMO conjunto pareado de altas.
-- ============================================================================
WITH alta AS (
  SELECT
    id_value,
    tip_doc,
    codmes_mrm AS codmes_d,
    DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(codmes_mrm, '%Y%m')), '%Y%m') AS codmes_dm1
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE flg_scope_ree = 1
    AND codmes_mrm <= '202604'
),
par AS (
  SELECT
    a.codmes_d,
    d.flg_clean    AS clean_d,
    d.flg_calib    AS calib_d,
    d.target_12m_60 AS y_d,
    m.flg_clean    AS clean_m,
    m.flg_calib    AS calib_m,
    m.pd_raw       AS pd_m,
    m.target_12m_60 AS y_m,
    CASE WHEN m.id_value IS NULL THEN 1 ELSE 0 END AS sin_fila_dm1
  FROM alta a
  INNER JOIN disc_model_owner.ds_stk_ree_pp_cal d
    ON  d.id_value   = a.id_value
    AND d.tip_doc    = a.tip_doc
    AND d.codmes_mrm = a.codmes_d
  LEFT JOIN disc_model_owner.ds_stk_ree_pp_cal m
    ON  m.id_value   = a.id_value
    AND m.tip_doc    = a.tip_doc
    AND m.codmes_mrm = a.codmes_dm1
)
SELECT
  COALESCE(SUBSTR(codmes_d, 1, 4), 'TOTAL') AS anio,
  COUNT(*)                                  AS n_alta,
  SUM(sin_fila_dm1)                         AS n_sin_fila_dm1,
  ROUND(100.0 * SUM(sin_fila_dm1) / COUNT(*), 2) AS pct_sin_fila_dm1,
  SUM(CASE WHEN sin_fila_dm1 = 0 AND pd_m IS NULL THEN 1 ELSE 0 END) AS n_sin_pd_dm1,
  SUM(CASE WHEN clean_d = 1 AND calib_d = 1 THEN 1 ELSE 0 END)       AS n_fit_d,
  SUM(CASE WHEN clean_m = 1 AND calib_m = 1 THEN 1 ELSE 0 END)       AS n_fit_dm1,
  SUM(CASE WHEN clean_d = 1 AND calib_d = 1
            AND clean_m = 1 AND calib_m = 1 THEN 1 ELSE 0 END)       AS n_par,
  ROUND(100.0 * AVG(CASE WHEN clean_d = 1 AND calib_d = 1
                          AND clean_m = 1 AND calib_m = 1 THEN y_d END), 4) AS lra_d_pct,
  ROUND(100.0 * AVG(CASE WHEN clean_d = 1 AND calib_d = 1
                          AND clean_m = 1 AND calib_m = 1 THEN y_m END), 4) AS lra_dm1_pct
FROM par
GROUP BY GROUPING SETS ((SUBSTR(codmes_d, 1, 4)), ())
ORDER BY 1
