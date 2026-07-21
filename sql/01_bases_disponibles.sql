-- Que bases/esquemas existen realmente en el catalogo.
-- Objetivo: confirmar si 'disc_monitoria' existe y como se llama exactamente.
select schema_name
from information_schema.schemata
order by schema_name
