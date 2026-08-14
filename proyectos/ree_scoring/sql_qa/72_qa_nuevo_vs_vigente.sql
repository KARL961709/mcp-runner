-- 72. EL CORTE NUEVO CONTRA EL VIGENTE, FILA A FILA, EN LOS 31 MESES COMUNES
--   se corre DESPUES de 71. Contrasta por llave, no por agregado: un promedio
--   igual no prueba que las filas coincidan.
--   Cualquier viol_* distinto de 0 es FALLA y hay que resolverlo antes de
--   publicar. max_dif_ft y max_dif_prob toleran del orden de 1e-8, que es la
--   precision del literal del cap medida en 13.
--   n_punt_distinta cuenta clientes cuyo entero se movio: se espera del orden de
--   la unidad, no mas.
SELECT a.codmes,
       COUNT(*)                                                                   AS n_comun,
       SUM(CASE WHEN a.trf_tipo_ingreso     <> b.trf_tipo_ingreso
                THEN 1 ELSE 0 END)                                                AS viol_tipo_ingreso,
       SUM(CASE WHEN a.trf_tipo_ingreso_dep <> b.trf_tipo_ingreso_dep
                THEN 1 ELSE 0 END)                                                AS viol_dep,
       SUM(CASE WHEN a.trf_flg_cs_estado    <> b.trf_flg_cs_estado
                THEN 1 ELSE 0 END)                                                AS viol_cs,
       SUM(CASE WHEN CAST(a.trf_falla_sin_tipo_ingreso AS INTEGER)
                  <> CAST(b.trf_falla_sin_tipo_ingreso AS INTEGER)
                THEN 1 ELSE 0 END)                                                AS viol_falla_ti,
       SUM(CASE WHEN CAST(a.trf_falla_sin_cta_sueldo AS INTEGER)
                  <> CAST(b.trf_falla_sin_cta_sueldo AS INTEGER)
                THEN 1 ELSE 0 END)                                                AS viol_falla_cs,
       MAX(ABS(CAST(a.trf_f_t AS DOUBLE) - CAST(b.trf_f_t AS DOUBLE)))            AS max_dif_ft,
       MAX(ABS(CAST(a.prob_modelo_cal AS DOUBLE)
             - CAST(b.prob_modelo_cal AS DOUBLE)))                                AS max_dif_prob,
       SUM(CASE WHEN CAST(a.puntuacion_cal AS INTEGER)
                  <> CAST(b.puntuacion_cal AS INTEGER)
                THEN 1 ELSE 0 END)                                                AS n_punt_distinta
  FROM disc_model_owner.scr_stk_ree_pp_cal_202608 a
  JOIN d_perm_aws.scr_stk_ree_pp_cal_202607 b
    ON b.key_value = a.key_value
   AND b.tip_doc   = a.tip_doc
   AND b.codmes    = a.codmes
 GROUP BY 1
 ORDER BY 1
