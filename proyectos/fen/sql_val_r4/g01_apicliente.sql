-- g01 T_DMDIRECCION_APICLIENTE -- la que resumen_fuentes marca como "explorar nueva"
--     por NOMBRE EXACTO: information_schema con LIKE barre miles de tablas y se cuelga
SELECT ordinal_position, column_name, data_type, extra_info
FROM information_schema.columns
WHERE table_schema = 'd_perm_aws' AND table_name = 't_dmdireccion_apicliente'
ORDER BY ordinal_position
LIMIT 100
