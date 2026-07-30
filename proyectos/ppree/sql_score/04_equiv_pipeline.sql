-- ============================================================================
-- 04 | Equivalencia contra el pipeline de calibracion.
--   Restringe el scoreo del stock a la MISMA poblacion sobre la que corrio la
--   calibracion (flg_calib = 1 y flg_clean = 1 de ds_stk_ree_pp_cal) y devuelve
--   los mismos agregados que produce full_calibrated.parquet, para contrastar
--   fila a fila del cuadro. Son 19 meses, de codmes_scr 202401 a 202507.
--   n_pd_raw_identica prueba ademas que la tabla nueva y la que leyo 50_pd
--   entregan la misma PD cruda sobre las mismas llaves.
-- ============================================================================
SELECT COALESCE(s.codmes, 'TOTAL')                                            AS codmes_scr,
       COUNT(*)                                                               AS n,
       SUM(CASE WHEN abs(s.probabilidad - c.pd_raw) < 1e-12 THEN 1 ELSE 0 END) AS n_pd_raw_identica,
       ROUND(100.0 * AVG(s.probabilidad), 4)                                  AS pd_raw_pct,
       ROUND(100.0 * AVG(s.prob_modelo_cal), 4)                               AS pd_cal_pct,
       ROUND(MAX(s.trf_f_t), 6)                                               AS f_t,
       ROUND(100.0 * AVG(CASE WHEN s.trf_tipo_ingreso_dep = 'DEP' THEN 1.0 ELSE 0.0 END), 2) AS pct_dep
FROM disc_model_owner.scr_stk_ree_pp_cal_202607 s
JOIN disc_model_owner.ds_stk_ree_pp_cal c
  ON c.codmes_scr = s.codmes
 AND c.tip_doc    = s.tip_doc
 AND c.id_value   = s.key_value
WHERE c.flg_calib = 1
  AND c.flg_clean = 1
GROUP BY GROUPING SETS ((s.codmes), ())
ORDER BY 1
