-- 09. HASTA DONDE LLEGA LA FUENTE DE CASTIGO
--   va aparte de 08 porque la llave es una fecha, no un codmes, y un cambio de
--   tipo ahi haria fallar todo el UNION de 08.
SELECT COUNT(*)                                                                   AS n,
       SUM(CASE WHEN ingreso_cj_fc IS NULL THEN 1 ELSE 0 END)                     AS n_sin_fecha,
       MIN(DATE_FORMAT(ingreso_cj_fc, '%Y%m'))                                    AS cm_min,
       MAX(DATE_FORMAT(ingreso_cj_fc, '%Y%m'))                                    AS cm_max
  FROM e_perm_aws.t_sco_maestro_cl_rsk
