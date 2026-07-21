-- Tablas cuyo nombre sugiere logica de restringidos, monitoria o grupos.
-- Sirve para ubicar DONDE vive la definicion vigente antes de opinar sobre ella.
select table_schema,
       table_name,
       table_type
from information_schema.tables
where lower(table_name) like '%restring%'
   or lower(table_name) like '%monitor%'
   or lower(table_name) like '%grupo%'
   or lower(table_name) like '%vinculad%'
order by table_schema, table_name
