-- Columnas cuyo nombre sugiere la marca de restringido, vivan donde vivan.
-- Muchas veces la logica no esta en una tabla "de restringidos" sino en un flag
-- dentro de una tabla mayor: esto lo encuentra igual.
select table_schema,
       table_name,
       column_name,
       data_type
from information_schema.columns
where lower(column_name) like '%restring%'
   or lower(column_name) like '%monitor%'
order by table_schema, table_name, column_name
