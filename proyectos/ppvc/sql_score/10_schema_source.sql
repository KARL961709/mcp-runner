-- ============================================================================
-- v00. Esquema de la fuente: confirmar que existen key_value + drivers + pd_raw.
-- ============================================================================
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner' AND table_name = 'ds_adm_pp_cdpp_cal'
  AND column_name IN ('key_value','sub_producto','tipo_ingreso','nodo','pd_raw','flg_calib')
ORDER BY column_name
