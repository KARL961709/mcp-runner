-- 51_existencia_madres.sql | en que esquema vive cada fuente madre de la cadena, para no descubrir a mitad de la construccion que una solo esta en uno de los dos
SELECT table_name,
       max(CASE WHEN table_schema = 'e_perm_aws' THEN 1 ELSE 0 END)   AS en_e_perm,
       max(CASE WHEN table_schema = 'd_perm_aws' THEN 1 ELSE 0 END)   AS en_d_perm,
       max(CASE WHEN column_name = 'p_codmes' THEN 1 ELSE 0 END)      AS tiene_p_codmes,
       max(CASE WHEN column_name = 'codmes' THEN 1 ELSE 0 END)        AS tiene_codmes,
       count(DISTINCT column_name)                                    AS n_cols
FROM information_schema.columns
WHERE table_schema IN ('e_perm_aws', 'd_perm_aws')
  AND table_name IN ('t_fact_report_rcc_rsk', 'tng_altas_ssff_rsk', 'tng_altas_ibk_rsk',
                     't_mst_ctaibk_rsk', 't_mst_ctarcc_rsk', 't_dim_inst_fin_rsk',
                     't_mst_reniec_rsk', 't_mst_fraude_rsk', 't_consolidado_rsk',
                     't_cob_facilidades_ejecutadas', 't_gdp_rcc_ppe', 't_ubigeo_hist',
                     't_calendar_summary', 'scr_vcnbank_rsk', 't_fact_bpe_vars_macro')
GROUP BY table_name
ORDER BY table_name
