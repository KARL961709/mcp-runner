-- 98_sunat_es_pit.sql | el estado SUNAT es reconstruible a la fecha del alta? Busca columnas de fecha, periodo o particion en las maestras. Si aparece p_codmes hay historia; si solo hay fechas de evento, se puede reconstruir; si no hay ninguna, el snapshot es irrecuperable y liberar el filtro es la unica opcion
SELECT table_name                                          AS tabla,
       count(1) OVER (PARTITION BY table_name)             AS cols_candidatas,
       ordinal_position                                    AS pos,
       column_name                                         AS columna,
       data_type                                           AS tipo
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws'
  AND table_name IN ('t_mst_princ_sunat_rsk',
                     't_mst_sec_sunat_rsk',
                     't_mst_rep_legal_sunat_rsk')
  AND regexp_like(lower(column_name),
                  'fec|fch|date|dia|mes|anio|ano|codmes|periodo|partic|p_|estado|condicion|baja|alta|inicio|cese|actualiz|carga|snapshot|version')
ORDER BY table_name, ordinal_position
