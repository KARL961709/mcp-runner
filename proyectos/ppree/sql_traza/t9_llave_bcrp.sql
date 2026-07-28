-- t9  primeras columnas de la tabla gobernada: ubica la llave temporal
-- (el filtro por nombre de t5 no encontro codmes/periodo/fecha)
SELECT ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws' AND table_name = 't_mst_bcrp_rsk'
  AND ordinal_position <= 12
ORDER BY ordinal_position
