-- e23_qa2_monotonia.sql | QA monotonia: PD sube con estres, puntuacion baja. Esperado: TODAS las violaciones = 0
SELECT
  SUM(CASE WHEN pd_esc2_fen70          < pd_esc1_base    - 1e-9 THEN 1 ELSE 0 END) AS v_esc2_lt_esc1,
  SUM(CASE WHEN pd_esc3_macropes       < pd_esc1_base    - 1e-9 THEN 1 ELSE 0 END) AS v_esc3_lt_esc1,
  SUM(CASE WHEN pd_esc4_macropes_fen50 < pd_esc2_fen70   - 1e-9 THEN 1 ELSE 0 END) AS v_esc4_lt_esc2,
  SUM(CASE WHEN pd_esc4_macropes_fen50 < pd_esc3_macropes- 1e-9 THEN 1 ELSE 0 END) AS v_esc4_lt_esc3,
  SUM(CASE WHEN punt_esc4_macropes_fen50 > punt_esc1_base THEN 1 ELSE 0 END)       AS v_punt_esc4_gt_base,
  SUM(CASE WHEN punt_esc2_fen70          > punt_esc1_base THEN 1 ELSE 0 END)       AS v_punt_esc2_gt_base
FROM disc_model_owner.fen_pd_escenarios_2609