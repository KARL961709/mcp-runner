-- diag_cols_desemb.sql | columnas de las fuentes de desembolsos (user_desembolso y b46029_desemb_cal_202609) en cualquier schema. Busca campos de FECHA (campana vs desembolso) para resolver que representa cod_mes. Read-only, schema.
SELECT table_schema, table_name, column_name, data_type
FROM information_schema.columns
WHERE table_name IN ('user_desembolso', 'b46029_desemb_cal_202609')
ORDER BY table_name, ordinal_position
