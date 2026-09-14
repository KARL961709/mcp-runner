-- 13_userdesemb_schema.sql | columnas y tipos de d_perm_aws.user_desembolso para arrastrar TODAS al insumo sin asumir cuales son. Solo metadata (information_schema), no escanea la tabla. READ-ONLY
SELECT ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'd_perm_aws' AND table_name = 'user_desembolso'
ORDER BY ordinal_position
