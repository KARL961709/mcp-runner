-- v1_reconciliacion.sql | G1. Los tres buckets de flg_clean tienen que sumar el universo del codmes, sin solape. Si
-- no cierra, o hay un filtro que devuelve NULL o hay una fila contada dos veces. Reporta magnitud, no solo veredicto.
SELECT 'G1'                                                                    AS gate,
       chk,
       n_viol,
       n_magnitud,
       CASE WHEN n_viol = 0 THEN 'PASS' ELSE 'FAIL' END                        AS veredicto
FROM (
    SELECT 'meses donde 99 + 1 + 0 no suma el universo'                        AS chk,
           sum(CASE WHEN n_tot <> n99 + n1 + n0 THEN 1 ELSE 0 END)             AS n_viol,
           sum(n_tot)                                                          AS n_magnitud
    FROM (
        SELECT codmes_mrm,
               count(*)                                            AS n_tot,
               sum(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END)     AS n99,
               sum(CASE WHEN flg_clean = 1  THEN 1 ELSE 0 END)     AS n1,
               sum(CASE WHEN flg_clean = 0  THEN 1 ELSE 0 END)     AS n0
        FROM disc_model_owner.ds_adm_tcnb_cal GROUP BY codmes_mrm) x
    UNION ALL
    SELECT 'filas con flg_clean fuera de 99, 1 y 0',
           sum(CASE WHEN flg_clean NOT IN (99,1,0) OR flg_clean IS NULL THEN 1 ELSE 0 END),
           count(*)
    FROM disc_model_owner.ds_adm_tcnb_cal
    UNION ALL
    SELECT 'filas con flg_calib fuera de 0 y 1',
           sum(CASE WHEN flg_calib NOT IN (0,1) OR flg_calib IS NULL THEN 1 ELSE 0 END),
           count(*)
    FROM disc_model_owner.ds_adm_tcnb_cal
) y
