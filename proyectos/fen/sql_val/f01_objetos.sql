-- f01 EXISTENCIA de los objetos FEN declarados en 01_inputs/INPUTS.md
SELECT table_schema, table_name, table_type
FROM information_schema.tables
WHERE (table_schema = 'disc_model_owner'
       AND (table_name LIKE 'grado_elnino%'
         OR table_name LIKE 'enr_%fem_3'
         OR table_name LIKE 'universo_altas%'
         OR table_name LIKE 'reniec_cod_grado%'
         OR table_name LIKE 'fen_stock_points%'))
   OR (table_schema = 'd_perm_aws'
       AND (table_name LIKE 'grado_elnino%' OR table_name = 't_mst_zonas_afectadas_tmp'))
ORDER BY 1, 2
