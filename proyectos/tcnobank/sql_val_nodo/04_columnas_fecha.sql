-- 04_columnas_fecha.sql | busca en las tres fuentes del nodo alguna columna de carga, proceso o auditoria. Contar filas por particion dice hasta donde llega el dato, no CUANDO llego. Si alguna tabla lleva timestamp de carga, la latencia real de publicacion se mide directo en vez de inferirla
SELECT table_name,
       column_name,
       data_type,
       ordinal_position
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws'
  AND table_name IN ('t_aws_360_cliente_mes_d3',
                     't_agg_retail_user_trx_plin',
                     't_rsk_cta_sueldo',
                     't_fact_edc_solicitud_retiro_afp_ibk')
  AND (   lower(column_name) LIKE '%fec%'
       OR lower(column_name) LIKE '%fch%'
       OR lower(column_name) LIKE '%date%'
       OR lower(column_name) LIKE '%_ts%'
       OR lower(column_name) LIKE 'ts_%'
       OR lower(column_name) LIKE '%carga%'
       OR lower(column_name) LIKE '%load%'
       OR lower(column_name) LIKE '%proces%'
       OR lower(column_name) LIKE '%audit%'
       OR lower(column_name) LIKE '%insert%'
       OR lower(column_name) LIKE '%codmes%')
ORDER BY table_name, ordinal_position
