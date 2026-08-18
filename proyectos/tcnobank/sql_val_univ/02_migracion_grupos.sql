-- 02. MIGRACION DE GRUPOS: la nueva calibracion contra la vigente
--   la pregunta que importa: cuanta gente cambia de decision de oferta al
--   reemplazar la calibracion. La diagonal es quien no se mueve.
--   El grupo nuevo se arma ACA con los cortes de la opcion B en vez de viajar
--   como columna: asi la tabla no fija un juego de cortes y cambiarlos no
--   obliga a reconstruir 800M de filas
SELECT grupo_cal_vigente,
       CASE WHEN puntuacion_cal IS NULL THEN NULL
            WHEN puntuacion_cal >= 972  THEN 'G1'
            WHEN puntuacion_cal >= 964  THEN 'G2'
            WHEN puntuacion_cal >= 938  THEN 'G3'
            WHEN puntuacion_cal >= 899  THEN 'G4'
            WHEN puntuacion_cal >= 768  THEN 'G5'
            ELSE                             'R'
       END                                                                       AS grupo_nuevo,
       COUNT(*)                                                                  AS n,
       AVG(pd_cal_vigente)                                                        AS pd_vigente_prom,
       AVG(prob_modelo_cal)                                                       AS pd_nueva_prom,
       AVG(CAST(puntuacion_cal_vigente AS DOUBLE))                                AS punt_vigente_prom,
       AVG(CAST(puntuacion_cal AS DOUBLE))                                        AS punt_nueva_prom
  FROM disc_model_owner.scr_univ_vcnbank_tc_cal
 GROUP BY grupo_cal_vigente,
       CASE WHEN puntuacion_cal IS NULL THEN NULL
            WHEN puntuacion_cal >= 972  THEN 'G1'
            WHEN puntuacion_cal >= 964  THEN 'G2'
            WHEN puntuacion_cal >= 938  THEN 'G3'
            WHEN puntuacion_cal >= 899  THEN 'G4'
            WHEN puntuacion_cal >= 768  THEN 'G5'
            ELSE                             'R'
       END
 ORDER BY 1, 2
