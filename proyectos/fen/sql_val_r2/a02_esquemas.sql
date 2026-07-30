-- a02 ESQUEMA REAL de las copias del grado y de las tablas IBK+ -- para escribir la ronda 3
SELECT table_schema, table_name, ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE (table_schema IN ('disc_model_owner','d_perm_aws')
       AND table_name IN ('grado_elnino_ubigeo_v3','grado_elnino_lookup_v3','grado_elnino_ubigeo_v2',
                          'grado_elnino_ubigeo','reniec_cod_grado_v3','reniec_cod_grado',
                          'ibk_indice_regional_categoria','ibk_indice_nacional_nominal'))
ORDER BY table_schema, table_name, ordinal_position
