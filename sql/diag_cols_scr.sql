-- diag_cols_scr.sql | columnas de score/probabilidad/puntuacion en scr_admbankbpe_rsk y scr_admbankbpe_calibrado, para saber de donde cruzar pd_raw, prob_modelo y puntuacion (todos a p_codmes = cod_mes - 1). Read-only, schema.
SELECT table_schema, table_name, column_name, data_type
FROM information_schema.columns
WHERE table_name IN ('scr_admbankbpe_rsk', 'scr_admbankbpe_calibrado_202607')
  AND (lower(column_name) LIKE '%prob%' OR lower(column_name) LIKE '%punt%' OR lower(column_name) LIKE '%codmes%' OR lower(column_name) IN ('tip_doc','key_value','modelo','fec_replica'))
ORDER BY table_name, ordinal_position
