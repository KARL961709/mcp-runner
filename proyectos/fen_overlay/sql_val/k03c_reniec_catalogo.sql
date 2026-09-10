-- k03c: que tablas RENIEC hay en disc_model_owner (por si existe una fuente mas completa donde SI esten los 3.83M faltantes) + las columnas de mca_bd_reniec_xy_r_reest (para ver si trae codmes/snapshot que pueda estar stale, o una llave alterna). Read-only, information_schema (no escanea datos)
SELECT 'tabla' AS tipo, table_name AS nombre, '' AS detalle
FROM information_schema.tables
WHERE table_schema = 'disc_model_owner' AND table_name LIKE '%reniec%'
UNION ALL
SELECT 'columna' AS tipo, column_name AS nombre, data_type AS detalle
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner' AND table_name = 'mca_bd_reniec_xy_r_reest'
ORDER BY tipo, nombre
