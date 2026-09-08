-- V7a. Probe del scoreo vigente: confirma tabla y nombres de columna antes de reconciliar.
--      Espera columnas: codmes, key_value, tip_doc, probabilidad, trf_tipo_ingreso_dep, trf_f_t, prob_modelo_cal.
SELECT *
  FROM d_perm_aws.scr_stk_ree_pp_cal_202607
 WHERE CAST(codmes AS VARCHAR) = '202606'
 LIMIT 5
