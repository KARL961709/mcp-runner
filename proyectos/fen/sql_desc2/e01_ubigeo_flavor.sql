SELECT ubigeo_reniec, ubigeo_sunat, departamento, provincia, distrito, poblacion
FROM e_perm_aws.t_mst_ubigeos_rsk
WHERE ubigeo_sunat IN ('150101','150137','200101','010101','040101','130101')
   OR ubigeo_reniec IN ('150101','150137','200101','010101','040101','130101')
ORDER BY ubigeo_sunat
