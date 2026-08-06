SELECT cod_ubi_domicilio, dep_ubi_domicilio, pro_ubi_domicilio, dis_ubi_domicilio, count(*) AS n
FROM e_perm_aws.t_mst_reniec_rsk
GROUP BY 1,2,3,4
ORDER BY n DESC
LIMIT 15
