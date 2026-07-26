-- e1f COBERTURA MAESTROS (conteos)
SELECT 'reniec'        AS fuente, COUNT(*) AS filas FROM e_perm_aws.t_mst_reniec_rsk
UNION ALL SELECT 'sunat_sec',      COUNT(*) FROM e_perm_aws.t_mst_sec_sunat_rsk
UNION ALL SELECT 'cliente_actual', COUNT(*) FROM e_perm_aws.t_mst_vpc_myp_cliente_actual
UNION ALL SELECT 'dim_inst_fin',   COUNT(*) FROM e_perm_aws.t_dim_inst_fin_rsk
UNION ALL SELECT 'bpe_giros',      COUNT(*) FROM e_perm_aws.t_mst_bpe_giros_restringidos
UNION ALL SELECT 'bpe_ubigeos',    COUNT(*) FROM e_perm_aws.t_mst_bpe_ubigeos_restringidos
