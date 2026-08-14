-- 01. RECONCILIACION Y COBERTURA
--   toda fila del ds_ esta en el scr_, y toda fila con pd_raw tiene score.
--   n_viol distinto de 0 en cualquiera de las cinco columnas viol_* es FALLA.
SELECT d.n_ds,
       s.n_scr,
       s.n_scr - d.n_ds                                                           AS dif_filas,
       s.n_con_pdraw,
       s.n_con_score,
       s.viol_pdraw_sin_score,
       s.viol_score_sin_pdraw,
       s.viol_score_con_motivo,
       s.viol_sin_score_sin_motivo,
       s.viol_punt_fuera_rango,
       100.0 * s.n_con_score / s.n_scr                                            AS pct_scoreado
  FROM (SELECT COUNT(*)                                                     AS n_scr,
               SUM(CASE WHEN pd_raw IS NOT NULL THEN 1 ELSE 0 END)          AS n_con_pdraw,
               SUM(CASE WHEN prob_modelo_cal IS NOT NULL THEN 1 ELSE 0 END) AS n_con_score,
               SUM(CASE WHEN pd_raw IS NOT NULL AND prob_modelo_cal IS NULL
                        THEN 1 ELSE 0 END)                                  AS viol_pdraw_sin_score,
               SUM(CASE WHEN pd_raw IS NULL AND prob_modelo_cal IS NOT NULL
                        THEN 1 ELSE 0 END)                                  AS viol_score_sin_pdraw,
               SUM(CASE WHEN prob_modelo_cal IS NOT NULL AND motivo_sin_score IS NOT NULL
                        THEN 1 ELSE 0 END)                                  AS viol_score_con_motivo,
               SUM(CASE WHEN prob_modelo_cal IS NULL AND motivo_sin_score IS NULL
                        THEN 1 ELSE 0 END)                                  AS viol_sin_score_sin_motivo,
               SUM(CASE WHEN puntuacion_cal < 0 OR puntuacion_cal > 1000
                        THEN 1 ELSE 0 END)                                  AS viol_punt_fuera_rango
          FROM disc_model_owner.scr_adm_vcnbank_tc_cal) s
 CROSS JOIN (SELECT COUNT(*) AS n_ds FROM disc_model_owner.ds_adm_vcnbank_tc_cal) d
