-- 07. MONOTONIA SOBRE LA TABLA ESCRITA
--   fijando mes, nodo y driver, mas pd_raw tiene que dar mas prob_modelo_cal.
--   Es la propiedad que hace usable un score: si se rompe, el orden de riesgo
--   no se respeta y los puntos de corte dejan de significar lo que dicen.
--   Se verifico sobre la FUNCION antes de correr, pero eso no prueba que la
--   TABLA la cumpla: un CASE mal armado la rompe sin dar error.
--   El decil se calcula en la subconsulta: una funcion de ventana no puede ir
--   en el GROUP BY, se evalua despues
SELECT nodo_calc,
       driver_c,
       decil,
       COUNT(*)                                                                   AS n,
       MIN(pd_raw)                                                                AS pd_raw_min,
       MAX(pd_raw)                                                                AS pd_raw_max,
       MIN(prob_modelo_cal)                                                       AS pd_cal_min,
       MAX(prob_modelo_cal)                                                       AS pd_cal_max
  FROM (SELECT nodo_calc,
               pd_raw,
               prob_modelo_cal,
               CASE WHEN seg_arq_salud = 'C' THEN 1 ELSE 0 END                    AS driver_c,
               NTILE(10) OVER (PARTITION BY nodo_calc,
                                            CASE WHEN seg_arq_salud = 'C' THEN 1 ELSE 0 END
                               ORDER BY pd_raw)                                   AS decil
          FROM disc_model_owner.scr_univ_vcnbank_tc_cal
         WHERE p_codmes = '202608') z
 GROUP BY nodo_calc, driver_c, decil
 ORDER BY 1, 2, 3
