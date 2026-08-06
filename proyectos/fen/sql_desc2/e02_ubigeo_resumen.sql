SELECT count(*) AS n_filas,
       count(DISTINCT ubigeo_reniec) AS n_reniec,
       count(DISTINCT ubigeo_sunat)  AS n_sunat,
       sum(CASE WHEN ubigeo_reniec = ubigeo_sunat THEN 1 ELSE 0 END) AS n_iguales,
       min(ubigeo_sunat) AS min_sunat, max(ubigeo_sunat) AS max_sunat
FROM e_perm_aws.t_mst_ubigeos_rsk
