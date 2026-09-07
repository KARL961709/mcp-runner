-- f01 columnas de ds_adm_pp_cdpp_cal, mca_bd_reniec_xy_r_reest y el puente t_mst_ubigeos_rsk
SELECT table_schema, table_name, ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_name IN ('ds_adm_pp_cdpp_cal','mca_bd_reniec_xy_r_reest','t_mst_ubigeos_rsk')
ORDER BY table_schema, table_name, ordinal_position
