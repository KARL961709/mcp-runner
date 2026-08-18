-- 02. MIGRACION DE GRUPOS: la nueva calibracion contra la vigente
--   la pregunta que importa. Cada celda es cuanta gente cambia de decision de
--   oferta al reemplazar la calibracion. La diagonal es quien no se mueve
SELECT grupo_cal_vigente,
       grupo_cal                                                                 AS grupo_nuevo,
       COUNT(*)                                                                  AS n,
       AVG(pd_cal_vigente)                                                       AS pd_vigente_prom,
       AVG(prob_modelo_cal)                                                      AS pd_nueva_prom,
       AVG(CAST(puntuacion_cal_vigente AS DOUBLE))                               AS punt_vigente_prom,
       AVG(CAST(puntuacion_cal AS DOUBLE))                                       AS punt_nueva_prom
  FROM disc_model_owner.scr_univ_vcnbank_tc_cal
 GROUP BY grupo_cal_vigente, grupo_cal
 ORDER BY 1, 2
