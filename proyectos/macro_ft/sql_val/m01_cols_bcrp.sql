-- m01. columnas de e_perm_aws.t_mst_bcrp_rsk (ver si trae var-12m ademas del porc_ipc mensual)
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws' AND table_name = 't_mst_bcrp_rsk'
ORDER BY ordinal_position
