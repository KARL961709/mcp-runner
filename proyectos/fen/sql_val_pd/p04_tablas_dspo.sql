-- p04 ¿Qué tablas PO existen y qué meses cubren? Antes de correr el análisis.
SELECT table_schema, table_name,
       array_join(array_agg(column_name ORDER BY ordinal_position), ' | ') AS columnas
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner'
  AND (table_name LIKE '%ds_po%' OR table_name LIKE '%dspo%')
GROUP BY table_schema, table_name
ORDER BY table_name
