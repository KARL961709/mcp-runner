-- h00 ubicar puntuacion_cal_ppfacil y el esquema de las tablas altas_ (para el grado con el CASE de Carlos)
SELECT table_schema, table_name, column_name, data_type
FROM information_schema.columns
WHERE lower(column_name) LIKE 'puntuacion%'
   OR (table_schema IN ('disc_model_owner','d_perm_aws','e_perm_aws') AND regexp_like(lower(table_name),'altas'))
ORDER BY table_schema, table_name, column_name
