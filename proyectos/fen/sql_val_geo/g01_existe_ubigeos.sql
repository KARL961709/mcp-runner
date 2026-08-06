-- g01 ¿Existe T_MST_UBIGEOS_RSK en AWS y qué trae?
-- Contesta la duda que dejó abierta 'describe tablas fen.txt':
--   TERADATA.E_DW_VIEWS.V_MAESTRA_UBIGEO  ==  E_PERM_AWS.T_MST_UBIGEOS_RSK ?
-- Si falla por tabla inexistente, esa es la respuesta y pasamos a t_dim_cliente.
SELECT table_schema,
       table_name,
       count(*)                                                  AS n_columnas,
       array_join(array_agg(column_name ORDER BY ordinal_position), ' | ') AS columnas
FROM information_schema.columns
WHERE lower(table_name) LIKE '%ubigeo%'
   OR lower(table_name) LIKE '%geoposition%'
GROUP BY table_schema, table_name
ORDER BY table_schema, table_name
