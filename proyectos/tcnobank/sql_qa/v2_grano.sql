-- v2_grano.sql | G2. El grano declarado es cliente x entidad x mes. Una llave repetida significa fan-out en algun
-- LEFT JOIN, que es el error silencioso mas caro de la cadena: no falla, solo duplica y mueve la LRA.
SELECT 'G2'                                                                    AS gate,
       chk, n_viol, n_magnitud,
       CASE WHEN n_viol = 0 THEN 'PASS' ELSE 'FAIL' END                        AS veredicto
FROM (
    SELECT 'llaves duplicadas en el maestro'                                   AS chk,
           count(*)                                                            AS n_viol,
           (SELECT count(*) FROM disc_model_owner.ds_adm_tcnb_cal)                                    AS n_magnitud
    FROM (SELECT codmes_mrm, tip_doc, id_value, entidad
          FROM disc_model_owner.ds_adm_tcnb_cal GROUP BY 1,2,3,4 HAVING count(*) > 1) d
    UNION ALL
    SELECT 'clientes con mas de una fila con prelacion_cod = 1',
           count(*),
           (SELECT count(*) FROM disc_model_owner.ds_adm_tcnb_cal WHERE prelacion_cod = 1)
    FROM (SELECT codmes_mrm, tip_doc, id_value
          FROM disc_model_owner.ds_adm_tcnb_cal WHERE prelacion_cod = 1 GROUP BY 1,2,3 HAVING count(*) > 1) p
) y
