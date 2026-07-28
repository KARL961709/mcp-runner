-- t5  esquema de la tabla gobernada BCRP: identifica la columna del IPC de Lima
-- devuelve las columnas candidatas (precio/ipc/inflacion/lima) y el total de columnas
SELECT 0 AS orden, 'TOTAL_COLUMNAS' AS column_name, CAST(COUNT(*) AS VARCHAR) AS data_type, NULL AS ordinal_position
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws' AND table_name = 't_mst_bcrp_rsk'
UNION ALL
SELECT 1, column_name, data_type, CAST(ordinal_position AS VARCHAR)
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws' AND table_name = 't_mst_bcrp_rsk'
  AND (LOWER(column_name) LIKE '%ipc%'
    OR LOWER(column_name) LIKE '%precio%'
    OR LOWER(column_name) LIKE '%inflac%'
    OR LOWER(column_name) LIKE '%lima%'
    OR LOWER(column_name) LIKE '%transable%'
    OR LOWER(column_name) LIKE '%codmes%'
    OR LOWER(column_name) LIKE '%periodo%'
    OR LOWER(column_name) LIKE '%fecha%')
ORDER BY 1, 4
