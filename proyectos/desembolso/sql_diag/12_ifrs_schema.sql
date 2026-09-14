-- 12_ifrs_schema.sql | columnas y tipos de e_perm_aws.t_ifrs_rcddeta_rsk para reconstruir la target desde esta fuente en lugar de t_fact_report_rcc_rsk. Solo metadata (information_schema), no escanea la tabla. READ-ONLY
SELECT ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws' AND table_name = 't_ifrs_rcddeta_rsk'
ORDER BY ordinal_position
