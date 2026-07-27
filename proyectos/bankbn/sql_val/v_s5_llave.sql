-- v_s5_llave.sql | dominio de tip_doc en el score: compatibilidad de la llave del join con el RCC
SELECT tip_doc,
       count(1)                    AS filas,
       count(DISTINCT key_value)   AS clientes,
       min(p_codmes)               AS desde,
       max(p_codmes)               AS hasta
FROM e_perm_aws.scr_admbankbpe_rsk
GROUP BY tip_doc
ORDER BY 2 DESC
