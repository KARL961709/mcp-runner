-- s00 PARTICIONES de las RM -- p_fecproceso_exp lleva prefijo p_, probablemente es llave de particion
--     si lo es, hay que filtrar al ultimo corte para no escanear historia ni duplicar personas
SELECT p_fecproceso_exp, count(*) AS n_filas
FROM d_perm_aws.t_rm_direccion_estandarizada
GROUP BY p_fecproceso_exp
ORDER BY 1 DESC
LIMIT 24
