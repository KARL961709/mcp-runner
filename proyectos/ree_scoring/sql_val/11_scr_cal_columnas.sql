-- 11. EL CONTRATO DE LA SALIDA VIGENTE
--   reemplaza a la version por information_schema, que dio TIMEOUT a los 903 s:
--   ese conector enumera el catalogo Glue entero antes de filtrar, y d_perm_aws
--   tiene miles de tablas. SHOW resuelve contra la tabla puntual.
--   Devuelve nombre y tipo por columna, que es lo que el mes nuevo debe emitir.
SHOW COLUMNS FROM d_perm_aws.scr_stk_ree_pp_cal_202607
