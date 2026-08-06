-- g03 ¿El target de PP vive en Athena, o solo en el parquet local de calibración?
-- Busca tablas con marca de incumplimiento del producto PP / prestamo personal.
SELECT table_schema,
       table_name,
       array_join(array_agg(column_name ORDER BY column_name), ' | ') AS columnas_target
FROM information_schema.columns
WHERE (lower(column_name) LIKE '%target%'
       OR lower(column_name) LIKE 'def%'
       OR lower(column_name) LIKE '%incumpl%')
  AND (lower(table_name) LIKE '%pp%'
       OR lower(table_name) LIKE '%stock%'
       OR lower(table_name) LIKE '%calib%')
GROUP BY table_schema, table_name
ORDER BY table_schema, table_name
