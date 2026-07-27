-- v_s7_entidades.sql | nombres reales de entidades y deteccion de tildes: n_bytes > n_chars implica no ASCII
SELECT cod_instit_financiera                        AS cod,
       max(nombre_instit_financiera)                AS nombre,
       length(max(nombre_instit_financiera))        AS n_chars,
       length(to_utf8(max(nombre_instit_financiera))) AS n_bytes
FROM e_perm_aws.t_dim_inst_fin_rsk
WHERE cod_instit_financiera = '00002'
   OR UPPER(nombre_instit_financiera) LIKE '%CREDITO%'
   OR UPPER(nombre_instit_financiera) LIKE '%SCOTIA%'
   OR UPPER(nombre_instit_financiera) LIKE '%BBVA%'
   OR UPPER(nombre_instit_financiera) LIKE '%CONTINENTAL%'
   OR UPPER(nombre_instit_financiera) LIKE '%INTERNACIONAL%'
   OR UPPER(nombre_instit_financiera) LIKE '%NACI%'
   OR UPPER(nombre_instit_financiera) LIKE '%AGROPECUARIO%'
   OR UPPER(nombre_instit_financiera) LIKE '%SIPAN%'
   OR UPPER(nombre_instit_financiera) LIKE '%LEASING%'
   OR UPPER(nombre_instit_financiera) LIKE '%NO ENVIADO%'
GROUP BY 1
ORDER BY 2
