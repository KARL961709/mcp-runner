-- e01 schema opt. Columnas y tipos. Confirma nombre exacto, probabilidad y llaves. Scan information_schema.
SELECT table_name, column_name, data_type, ordinal_position
FROM information_schema.columns
WHERE table_schema = 'disc_riesgos' AND table_name LIKE 'scr_vcbankv3_repro_opt%'
ORDER BY table_name, ordinal_position
