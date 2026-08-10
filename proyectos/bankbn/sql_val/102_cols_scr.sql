-- 102_cols_scr.sql | columnas de la fuente del score, en orden. Necesarias para reescribir la tabla calibrada conservando TODAS las columnas originales y solo agregando las de calibracion
SELECT ordinal_position AS pos,
       column_name      AS columna,
       data_type        AS tipo
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws'
  AND table_name = 'scr_admbankbpe_rsk'
ORDER BY ordinal_position
