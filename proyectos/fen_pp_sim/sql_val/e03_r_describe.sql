-- e03_r_describe.sql | describe R reest en d_perm_aws Y disc_model_owner: llave (key_value), r_label, r_label_reest, r_nivel_reest, lon_final/lat_final, ubigeo_inei_nodo, exp25/50
SELECT table_schema, column_name, data_type
FROM information_schema.columns
WHERE table_name = 'mca_bd_reniec_xy_r_reest'
  AND table_schema IN ('d_perm_aws', 'disc_model_owner')
ORDER BY table_schema, ordinal_position
