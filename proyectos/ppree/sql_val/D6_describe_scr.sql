-- ============================================================================
-- D6. DESCRIBE de la tabla calibrada desplegada (existente y legible):
--   d_perm_aws.scr_stk_ree_pp_cal_202607 (la que V5 ya leyo).
--   Da los tipos reales de trf_f_t, prob_modelo_cal, puntuacion_cal,
--   trf_tipo_ingreso_dep, probabilidad -> confirma la precision del trf_f_t
--   (nota de V5) y sirve de referencia de tipos calibrados.
--   (El scr propio scr_cppibkren_rsk se crea en disc_model_owner; sus tipos
--    los fija el diccionario ya corregido.)
-- ============================================================================
DESCRIBE d_perm_aws.scr_stk_ree_pp_cal_202607
