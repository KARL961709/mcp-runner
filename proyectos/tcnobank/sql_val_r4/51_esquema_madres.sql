-- 51_esquema_madres.sql | existencia, esquema y columnas de TODAS las fuentes madre en un solo tiro. Una fila por tabla con la lista completa de campos, para no volver a preguntar por un nombre de columna en otro viaje
SELECT table_schema,
       table_name,
       count(*)                                                            AS n_cols,
       array_join(array_agg(column_name ORDER BY ordinal_position), ' | ') AS columnas
FROM information_schema.columns
WHERE table_schema IN ('e_perm_aws', 'd_perm_aws')
  AND table_name IN ('t_rsk_fct_altas_tc', 'tng_altas_ssff_rsk', 'tng_altas_ibk_rsk',
                     't_fact_report_rcc_rsk', 't_mst_ctaibk_rsk', 't_mst_ctarcc_rsk',
                     't_dim_inst_fin_rsk', 't_mst_reniec_rsk', 't_mst_fraude_rsk',
                     't_consolidado_rsk', 't_cob_facilidades_ejecutadas', 't_gdp_rcc_ppe',
                     't_ubigeo_hist', 't_fact_bpe_vars_macro')
GROUP BY table_schema, table_name
ORDER BY table_name, table_schema
