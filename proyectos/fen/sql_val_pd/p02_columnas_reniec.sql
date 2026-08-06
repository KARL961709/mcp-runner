-- p02 Columnas reales de RENIEC y del lookup FEN, para no adivinar nombres.
SELECT table_schema, table_name,
       array_join(array_agg(column_name ORDER BY ordinal_position), ' | ') AS columnas
FROM information_schema.columns
WHERE (table_schema = 'e_perm_aws'      AND table_name = 't_mst_reniec_rsk')
   OR (table_schema = 'disc_model_owner' AND table_name LIKE 'fen_score%')
   OR (table_schema = 'disc_model_owner' AND table_name LIKE 'grado_elnino%')
GROUP BY table_schema, table_name
ORDER BY table_schema, table_name
