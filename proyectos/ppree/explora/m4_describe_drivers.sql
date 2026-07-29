-- m4  contrato de las fuentes de driver: m2 fallo porque no tienen key_value
-- Se listan sus columnas para saber con que llave cruzan contra el stock
SELECT table_name, ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws'
  AND table_name IN ('ds_rtd_rskvol_cas_ingr_ir', 't_rsk_cta_sueldo')
ORDER BY table_name, ordinal_position
