-- g02 ESQUEMA y particion de t_dim_cliente -- la geo que cubre ~100% del stock
SELECT ordinal_position, column_name, data_type, extra_info
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws' AND table_name = 't_dim_cliente'
ORDER BY ordinal_position
LIMIT 100
