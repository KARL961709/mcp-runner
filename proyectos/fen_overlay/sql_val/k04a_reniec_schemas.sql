-- k04a: confirma que las tablas RENIEC candidatas (mas anchas que r_reest) tengan key_value + geo, ANTES de cruzarlas. Evita el fallo tipo k03b (columna inexistente). Read-only, information_schema
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner'
  AND table_name IN (
    'mca_bd_reniec_xy_distancias',
    'mca_bd_reniec_xy_con_r',
    'mca_bd_reniec_xy_distancias_sin_r',
    'mca_bd_reniec_xy_con_r_fen',
    'enr_dataset_cliente_reniec_validado')
  AND column_name IN ('key_value','ubigeo_inei_nodo','ubigeo_formato_inei','r_nivel','r_nivel_reest','lat_final','lon_final')
ORDER BY table_name, column_name
