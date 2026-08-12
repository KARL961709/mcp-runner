-- 01_existencia.sql | confirma que existen las tablas de los dos modelos y en que esquema viven, antes de asumir nombres
SELECT table_schema,
       table_name,
       table_type
FROM information_schema.tables
WHERE table_schema IN ('e_perm_aws', 'd_perm_aws')
  AND table_name IN ('ds_flg_admtcnobk1_rsk', 'scr_admtcnobk1_rsk', 'scr_vcnbank_rsk', 'ds_vcnbank_rsk',
                     'tng_altas_ssff_rsk', 'tng_altas_ibk_rsk', 'ds_vc_mvp_no_bank_gdp_kat',
                     'v_vc_mvp_no_bank_gdp_kat', 'ds_vc_mvp_no_bank_gdp_target_kat',
                     'ds_nobank_rsk_target_vars3', 't_inca_sa', 't_inca_vnb', 't_dim_inst_fin_rsk')
ORDER BY table_schema, table_name
