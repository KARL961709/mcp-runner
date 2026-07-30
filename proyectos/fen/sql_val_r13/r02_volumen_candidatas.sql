-- r02 VOLUMEN de las candidatas -- sin asumir ninguna columna, solo count(*)
SELECT 't_rm_direccion_estandarizada'    AS tabla, count(*) AS n_filas FROM d_perm_aws.t_rm_direccion_estandarizada
UNION ALL SELECT 't_rm_direccion_noestandarizada', count(*) FROM d_perm_aws.t_rm_direccion_noestandarizada
UNION ALL SELECT 't_mst_ccd_direccion',            count(*) FROM d_perm_aws.t_mst_ccd_direccion
UNION ALL SELECT 't_cob_direccion',                count(*) FROM d_perm_aws.t_cob_direccion
UNION ALL SELECT 't_sgi_gtp_direcciones',          count(*) FROM d_perm_aws.t_sgi_gtp_direcciones
ORDER BY 2 DESC
