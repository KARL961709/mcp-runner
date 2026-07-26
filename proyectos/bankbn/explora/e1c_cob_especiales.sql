-- e1c COBERTURA ESPECIALES (base negativa/vigilancia)
SELECT 'especiales_negativo' AS fuente, COUNT(*) AS filas,
       MIN(CAST(fecha_dt AS VARCHAR)) AS min_fecha, MAX(CAST(fecha_dt AS VARCHAR)) AS max_fecha
FROM e_perm_aws.t_rel_vpc_myp_clientenegativo
