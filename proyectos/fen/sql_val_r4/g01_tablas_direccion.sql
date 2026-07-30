-- g01 DESCUBRIMIENTO -- que tablas de direccion/domicilio/ubigeo existen y con que columnas
SELECT c.table_schema, c.table_name, c.ordinal_position, c.column_name, c.data_type, c.extra_info
FROM information_schema.columns c
WHERE c.table_schema IN ('e_perm_aws','d_perm_aws')
  AND (lower(c.table_name) LIKE '%direccion%'
    OR lower(c.table_name) LIKE '%domicilio%'
    OR lower(c.table_name) LIKE '%apicliente%')
ORDER BY 1, 2, 3
LIMIT 100
