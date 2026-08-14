-- 12. PERFIL AGREGADO DE LA SALIDA VIGENTE
--   sin detalle de cliente: solo volumen, rango y momentos de las dos columnas
--   calibradas. prob_prom es el numero contra el que voy a contrastar mi
--   reproduccion de la cadena antes de escribir el mes nuevo.
--   Si falla por nombre de columna, 11 devuelve el esquema real.
SELECT COUNT(*)                                                                   AS n,
       COUNT(DISTINCT CAST(codmes AS VARCHAR))                                    AS n_meses,
       MIN(CAST(codmes AS VARCHAR))                                               AS cm_min,
       MAX(CAST(codmes AS VARCHAR))                                               AS cm_max,
       SUM(CASE WHEN prob_modelo_cal IS NULL THEN 1 ELSE 0 END)                   AS n_sin_prob,
       AVG(CAST(prob_modelo_cal AS DOUBLE))                                       AS prob_prom,
       MIN(CAST(prob_modelo_cal AS DOUBLE))                                       AS prob_min,
       MAX(CAST(prob_modelo_cal AS DOUBLE))                                       AS prob_max,
       AVG(CAST(puntuacion_cal AS DOUBLE))                                        AS punt_prom,
       MIN(CAST(puntuacion_cal AS DOUBLE))                                        AS punt_min,
       MAX(CAST(puntuacion_cal AS DOUBLE))                                        AS punt_max
  FROM d_perm_aws.scr_stk_ree_pp_cal_202607
