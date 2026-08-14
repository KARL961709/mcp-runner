-- 11b. RESPALDO DE 11, POR SI SHOW NO TOLERA LA CABECERA
--   LIMIT 0 devuelve el encabezado del CSV y cero filas de dato: da los nombres
--   de columna en el orden real, sin sacar un solo registro del entorno.
--   Pierde los tipos, que es justo lo que aporta 11.
SELECT *
  FROM d_perm_aws.scr_stk_ree_pp_cal_202607
 LIMIT 0
