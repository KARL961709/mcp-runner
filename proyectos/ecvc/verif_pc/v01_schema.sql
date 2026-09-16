-- v01 descubre donde vive puntuacion/prob modelo cal (altas_ec_cal single vs tabla _ec multi). Scan information_schema.
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner'
  AND (column_name LIKE 'puntuacion_modelo_cal%' OR column_name LIKE 'prob_modelo_cal%')
  AND (table_name LIKE 'altas%' OR table_name LIKE '%ec%cal%')
ORDER BY table_name, column_name
