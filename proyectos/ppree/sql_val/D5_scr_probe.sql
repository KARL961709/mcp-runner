-- ============================================================================
-- D5. UBICA la(s) tabla(s) scr/ds del modelo cppibkren y si ya traen prob_modelo
--   Paso previo a la reproduccion del pkl: si el scr ya tiene una corrida con
--   prob_modelo, D5 se cierra comparando prob_modelo (salida del pkl) vs
--   pd_comppp_reen_itc (v5) por llave. Si no, D5 va por rescore en Python.
-- ============================================================================
SELECT table_schema,
       table_name,
       count(*)                                                                  AS n_cols,
       sum(CASE WHEN lower(column_name) IN ('prob_modelo','probabilidad','pd',
                                            'pd_comppp_reen_itc') THEN 1 ELSE 0 END) AS tiene_prob,
       sum(CASE WHEN lower(column_name) IN ('prob_modelo_cal','trf_f_t',
                                            'trf_tipo_ingreso_dep') THEN 1 ELSE 0 END) AS tiene_calib
  FROM information_schema.columns
 WHERE lower(table_name) LIKE '%cppibkren%'
 GROUP BY 1, 2
 ORDER BY 1, 2
