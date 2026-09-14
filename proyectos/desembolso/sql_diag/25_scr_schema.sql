-- 25_scr_schema.sql | esquema completo de e_perm_aws.scr_admbankbpe_rsk para encontrar el mes de NEGOCIO (codmes/cod_mes/periodo/fecha/campania) distinto de p_codmes (que es la particion de descarga). Los scripts originales solo usaron p_codmes, tip_doc, key_value y probabilidad; hay que ver si existe un campo de mes de negocio para cruzar por ahi. Solo metadata. READ-ONLY
SELECT ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws' AND table_name = 'scr_admbankbpe_rsk'
ORDER BY ordinal_position
