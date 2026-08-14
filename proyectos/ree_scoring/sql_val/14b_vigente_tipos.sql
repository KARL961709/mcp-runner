-- 14b. TIPOS DE LAS TRECE COLUMNAS DEL CONTRATO
--   SHOW COLUMNS devolvio los nombres pero el tipo no sobrevivio al CSV. typeof
--   lo resuelve con una sola fila y sin sacar dato: devuelve el nombre del tipo,
--   no el valor. El CTAS castea explicito contra esto.
SELECT typeof(codmes)                                                             AS t_codmes,
       typeof(tip_doc)                                                            AS t_tip_doc,
       typeof(key_value)                                                          AS t_key_value,
       typeof(probabilidad)                                                       AS t_probabilidad,
       typeof(puntuacion)                                                         AS t_puntuacion,
       typeof(trf_tipo_ingreso)                                                   AS t_trf_tipo_ingreso,
       typeof(trf_tipo_ingreso_dep)                                               AS t_trf_tipo_ingreso_dep,
       typeof(trf_flg_cs_estado)                                                  AS t_trf_flg_cs_estado,
       typeof(trf_falla_sin_tipo_ingreso)                                          AS t_trf_falla_ti,
       typeof(trf_falla_sin_cta_sueldo)                                           AS t_trf_falla_cs,
       typeof(trf_f_t)                                                            AS t_trf_f_t,
       typeof(prob_modelo_cal)                                                     AS t_prob_modelo_cal,
       typeof(puntuacion_cal)                                                     AS t_puntuacion_cal
  FROM d_perm_aws.scr_stk_ree_pp_cal_202607
 LIMIT 1
