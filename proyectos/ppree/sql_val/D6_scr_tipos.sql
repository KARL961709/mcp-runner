-- ============================================================================
-- D6. TIPOS REALES de las columnas de calibracion en el scr y en el ds
--   Resuelve los conflictos del diccionario: grupo_calibracion (int?), extra_01,
--   trf_macro01/02, y si el ds ya tiene trf_tipo_ingreso_dep/trf_f_t.
-- ============================================================================
SELECT table_schema,
       table_name,
       column_name,
       data_type
  FROM information_schema.columns
 WHERE lower(table_name) LIKE '%cppibkren%'
   AND lower(column_name) IN ('grupo_calibracion','prob_modelo_cal','puntuacion_cal',
                              'extra_01','trf_macro01','trf_macro02','segmento',
                              'ts_carga','fec_replica','prob_modelo','puntuacion',
                              'trf_tipo_ingreso_dep','trf_f_t','trf_ipc_x')
 ORDER BY table_schema, table_name, column_name
