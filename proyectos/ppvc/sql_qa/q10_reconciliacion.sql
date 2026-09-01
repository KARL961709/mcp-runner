-- ============================================================================
-- q10. Reconciliacion scr_ppvc_cal vs fuente: mismo universo, 0 filas perdidas.
-- ============================================================================
SELECT
  (SELECT COUNT(*) FROM disc_model_owner.scr_ppvc_cal) AS n_scr,
  (SELECT COUNT(*) FROM disc_model_owner.ds_adm_pp_cdpp_cal WHERE flg_ibk = 1 AND flg_calib = 1 AND pd_raw IS NOT NULL AND sub_producto IN ('PP_FACIL', 'PP_CD')) AS n_src,
  (SELECT COUNT(*) FROM disc_model_owner.scr_ppvc_cal)
    - (SELECT COUNT(*) FROM disc_model_owner.ds_adm_pp_cdpp_cal WHERE flg_ibk = 1 AND flg_calib = 1 AND pd_raw IS NOT NULL AND sub_producto IN ('PP_FACIL', 'PP_CD')) AS dif,
  (SELECT COUNT(DISTINCT codmes) FROM disc_model_owner.scr_ppvc_cal) AS n_meses,
  (SELECT MIN(codmes) FROM disc_model_owner.scr_ppvc_cal) AS codmes_min,
  (SELECT MAX(codmes) FROM disc_model_owner.scr_ppvc_cal) AS codmes_max
