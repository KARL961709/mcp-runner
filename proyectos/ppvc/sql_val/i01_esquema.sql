-- ============================================================================
-- i01. ESQUEMA de ds_adm_pp_cdpp_cal. READ-ONLY.
--   Confirma que la tabla existe y sus columnas. 0 filas = no existe (habria
--   que construirla desde los Recibidos antes de calibrar).
-- ============================================================================
SELECT column_name, data_type, ordinal_position
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner' AND table_name = 'ds_adm_pp_cdpp_cal'
ORDER BY ordinal_position
