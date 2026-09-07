-- c07. Maestros (snapshot, sin periodo): confirma que existen y tienen filas.
SELECT 'sunarp' AS t, COUNT(*) AS n FROM e_perm_aws.t_sunarp_inmueble
UNION ALL SELECT 'profesiones', COUNT(*) FROM e_perm_aws.t_maestra_profesiones
UNION ALL SELECT 'ctarcc_sbs', COUNT(*) FROM e_perm_aws.t_mst_ctarcc_rsk
