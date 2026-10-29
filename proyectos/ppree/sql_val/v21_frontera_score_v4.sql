-- ============================================================================
-- v21. FRONTERA de la fuente de score v4, contando filas
--   codmes_scr = codmes_mrm + 1, asi que una cohorte 202609 necesita 202610 aqui.
--   Si el techo esta en esta tabla y no en la madre, el export 96 no alcanza 202609.
-- ============================================================================
SELECT
  CAST(codmes AS VARCHAR)                                                        AS codmes_scr,
  COUNT(*)                                                                       AS n,
  SUM(CASE WHEN pd_comppp_reen_itc IS NOT NULL THEN 1 ELSE 0 END)                AS n_pd,
  SUM(CASE WHEN pd_comppp_reen_itc > 0 AND pd_comppp_reen_itc < 1 THEN 1 ELSE 0 END) AS n_pd_rango,
  SUM(CASE WHEN CAST(flg_reenganche AS INTEGER) = 1 THEN 1 ELSE 0 END)           AS n_reen
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
WHERE CAST(codmes AS VARCHAR) >= '202505'
GROUP BY CAST(codmes AS VARCHAR)
ORDER BY 1
