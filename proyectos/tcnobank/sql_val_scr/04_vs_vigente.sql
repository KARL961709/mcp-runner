-- 04. LA CALIBRACION NUEVA CONTRA LA VIGENTE
--   sobre la poblacion de calibracion. La columna dif_pp es lo que cambia el
--   nivel de PD al reemplazar las dos columnas en produccion.
SELECT codmes_mrm,
       COUNT(*)                                                                   AS n,
       AVG(pd_raw)                                                                AS pd_raw_prom,
       AVG(pd_cal_vigente)                                                        AS cal_vigente_prom,
       AVG(prob_modelo_cal)                                                       AS cal_nueva_prom,
       100.0 * (AVG(prob_modelo_cal) - AVG(pd_cal_vigente))                       AS dif_pp,
       AVG(CAST(puntuacion_cal_vigente AS DOUBLE))                                AS punt_vigente_prom,
       AVG(CAST(puntuacion_cal AS DOUBLE))                                        AS punt_nueva_prom
  FROM disc_model_owner.scr_adm_vcnbank_tc_cal
 WHERE flg_calib = 1 AND flg_clean = 1 AND entidad = '00002'
 GROUP BY 1
 ORDER BY 1
