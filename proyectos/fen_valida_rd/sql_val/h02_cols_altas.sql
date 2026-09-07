-- h02 columnas reales de disc_model_owner.altas_adm_pp_cdpp_cal (nombre real del score + demas)
SELECT ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner' AND table_name = 'altas_adm_pp_cdpp_cal'
ORDER BY ordinal_position
