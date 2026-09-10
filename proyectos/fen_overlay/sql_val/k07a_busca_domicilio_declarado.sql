-- k07a: busca en TODAS las tablas reniec una columna de domicilio DECLARADO (ubigeo o dept/prov/dist) para reconstruir el R directo distrital de los 3.83M sin XY. Los 3 R (dir/geo/reest) solo viven en mca_bd_reniec_xy_r_reest (9.1M, requiere XY). Si el distrito declarado vive en otra tabla keyed by key_value, se arma r_dir para los que no tienen XY. Read-only, information_schema
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner'
  AND table_name LIKE '%reniec%'
  AND (lower(column_name) LIKE '%ubigeo%'
    OR lower(column_name) LIKE '%domicil%'
    OR lower(column_name) LIKE '%depart%'
    OR lower(column_name) LIKE '%provin%'
    OR lower(column_name) LIKE '%distrit%'
    OR lower(column_name) LIKE '%dpto%')
ORDER BY table_name, column_name
