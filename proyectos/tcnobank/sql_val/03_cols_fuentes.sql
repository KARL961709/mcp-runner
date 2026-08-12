-- 03_cols_fuentes.sql | esquema compacto de altas, scores y drivers: una fila por tabla con todas sus columnas concatenadas
SELECT table_schema,
       table_name,
       count(*) AS n_cols,
       array_join(array_agg(column_name ORDER BY ordinal_position), ' | ') AS columnas
FROM information_schema.columns
WHERE table_schema IN ('e_perm_aws', 'd_perm_aws')
  AND table_name IN ('tng_altas_ssff_rsk', 'tng_altas_ibk_rsk', 'scr_vcnbank_rsk', 'scr_admtcnobk1_rsk',
                     't_inca_sa', 't_inca_vnb', 'ds_vc_mvp_no_bank_gdp_target_kat')
GROUP BY table_schema, table_name
ORDER BY table_schema, table_name
