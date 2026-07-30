-- r01 ESQUEMAS de las tablas de direccion que aparecieron en q04 -- nombres EXACTOS (el LIKE se cuelga)
SELECT table_name, ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'd_perm_aws'
  AND table_name IN ('t_rm_direccion_estandarizada','t_rm_direccion_noestandarizada',
                     't_mst_ccd_direccion','t_cob_direccion','t_sgi_gtp_direcciones')
ORDER BY table_name, ordinal_position
LIMIT 100
