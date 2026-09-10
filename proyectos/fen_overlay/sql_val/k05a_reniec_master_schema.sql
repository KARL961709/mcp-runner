-- k05a: columnas de las tablas RENIEC crudas (master via API) para ubicar la LLAVE de join y el UBIGEO de domicilio DECLARADO de los 3.83M sin XY. OJO trap: ubigeo RENIEC != INEI, el puente es t_mst_ubigeos_rsk (memoria ubigeo-reniec-vs-inei). Read-only, information_schema
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner'
  AND table_name IN ('t_mst_reniec_rsk_api', 'mca_reniec_api')
ORDER BY table_name, ordinal_position
