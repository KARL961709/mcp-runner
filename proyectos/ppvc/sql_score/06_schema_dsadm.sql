-- ============================================================================
-- 06. Esquema completo de ds_adm_pp_cdpp_cal (llaves del join: cod_tip_doc/tip_doc/key_value).
-- ============================================================================
SELECT ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner' AND table_name = 'ds_adm_pp_cdpp_cal'
ORDER BY ordinal_position
