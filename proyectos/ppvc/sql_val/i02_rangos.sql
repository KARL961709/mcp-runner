-- ============================================================================
-- i02. RANGOS de codmes: total, con score (pd_raw), con target maduro. READ-ONLY.
--   Fija la ventana: SCORE_INI = min con pd_raw, COHORTE_FIN = max con target_12m.
-- ============================================================================
SELECT
  min(codmes)                                            AS codmes_min,
  max(codmes)                                            AS codmes_max,
  min(CASE WHEN flg_pd_raw = 1 THEN codmes END)          AS codmes_min_score,
  max(CASE WHEN flg_pd_raw = 1 THEN codmes END)          AS codmes_max_score,
  min(CASE WHEN target_12m IS NOT NULL THEN codmes END)  AS codmes_min_maduro,
  max(CASE WHEN target_12m IS NOT NULL THEN codmes END)  AS codmes_max_maduro,
  count(*)                                               AS n_total
FROM disc_model_owner.ds_adm_pp_cdpp_cal
