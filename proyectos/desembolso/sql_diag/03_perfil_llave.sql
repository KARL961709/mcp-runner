-- 03_perfil_llave.sql | formato de la llave de user_desembolso: distribucion de cod_tip_doc y del largo de key_value, para cruzar bien contra RCC (target) y contra las tablas de scoring (pd_raw). Ceros a la izquierda y tipo de doc deciden el match. READ-ONLY
SELECT cod_tip_doc,
       length(key_value) AS largo_kv,
       count(*) AS n,
       count(distinct key_value) AS n_cli
FROM d_perm_aws.user_desembolso
GROUP BY cod_tip_doc, length(key_value)
ORDER BY n DESC
