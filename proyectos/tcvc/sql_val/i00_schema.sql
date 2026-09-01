-- i00. E0 contrato fisico: columnas de las 3 tablas de la cadena TC.
SELECT table_name, ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner'
  AND table_name IN ('ds_adm_tcbank_cal', 'enr_admtcbk_2_v2', 'enr_admtcbk_1_v2')
ORDER BY table_name, ordinal_position