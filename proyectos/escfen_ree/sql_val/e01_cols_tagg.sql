-- e01. columnas de e_perm_aws.t_agg_comppree_rsk (fuente FREEZE)
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws' AND table_name = 't_agg_comppree_rsk'
ORDER BY ordinal_position
