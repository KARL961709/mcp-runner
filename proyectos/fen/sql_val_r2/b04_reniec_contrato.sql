-- b04 CONTRATO FISICO de RENIEC -- grano, formato de la llave y cobertura de nombres
SELECT tip_doc,
       count(*)                                                          AS n_filas,
       count(DISTINCT key_value)                                         AS n_key,
       min(length(key_value))                                            AS len_min,
       max(length(key_value))                                            AS len_max,
       sum(CASE WHEN dis_ubi_domicilio IS NULL THEN 1 ELSE 0 END)        AS sin_distrito,
       sum(CASE WHEN dep_ubi_domicilio <> trim(dep_ubi_domicilio) THEN 1 ELSE 0 END) AS dep_con_espacios
FROM e_perm_aws.t_mst_reniec_rsk
GROUP BY tip_doc
ORDER BY 2 DESC
LIMIT 20
