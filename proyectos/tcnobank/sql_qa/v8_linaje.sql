-- v8_linaje.sql | G8. Control de anclas. Los filtros de pasado y de origen no pueden disparar en meses donde su
-- fuente todavia no existe: fraude arranca en 202106 y los swaps en 202201. Si disparan antes, el join esta leyendo
-- algo fuera de ventana. Y ctrl_sin_fraude marca esos meses, asi que la interseccion tiene que ser cero.
SELECT 'G8'                                                                    AS gate,
       chk, n_viol, n_magnitud,
       CASE WHEN n_viol = 0 THEN 'PASS' ELSE 'FAIL' END                        AS veredicto
FROM (
    SELECT 'fraude que dispara antes de 202106'                                AS chk,
           sum(CASE WHEN ctrl_sin_fraude = 1 AND f_fraude = 1 THEN 1 ELSE 0 END) AS n_viol,
           sum(ctrl_sin_fraude)                                                AS n_magnitud
    FROM disc_model_owner.ds_adm_tcnb_cal
    UNION ALL
    SELECT 'swap u12m que dispara antes de 202201',
           sum(CASE WHEN ctrl_sin_swap = 1 AND f_swap_u12m = 1 THEN 1 ELSE 0 END),
           sum(ctrl_sin_swap)
    FROM disc_model_owner.ds_adm_tcnb_cal
    UNION ALL
    SELECT 'inca que trae dato antes de 202305',
           sum(CASE WHEN codmes_mrm < '202305' AND ctrl_inca_sin_dato = 0 THEN 1 ELSE 0 END),
           sum(CASE WHEN codmes_mrm < '202305' THEN 1 ELSE 0 END)
    FROM disc_model_owner.ds_adm_tcnb_cal
    UNION ALL
    SELECT 'altas fuera de la ventana declarada 201902 a 202506',
           sum(CASE WHEN codmes_mrm < '201902' OR codmes_mrm > '202506' THEN 1 ELSE 0 END),
           count(*)
    FROM disc_model_owner.ds_adm_tcnb_cal
) y
