-- ============================================================================
-- D20. QUE DE LO QUE USA LA LOGICA DE NODOS EXISTE EN AWS
--   scan: information_schema.tables de los tres esquemas
--   ancla: el script lee ~50 tablas t_edc_sd_ en datalab_risk_people_banking, mas
--          bds.lcl_maepersona y oracle_exadata_dwhcyg, que son on-prem. Antes de
--          proponer ajustes hay que saber que se alcanza desde Athena
-- ============================================================================
SELECT table_schema,
       table_name,
       table_type
FROM information_schema.tables
WHERE table_schema IN ('e_perm_aws','d_perm_aws','datalab_risk_people_banking')
  AND (   table_name IN ('t_agg_retail_user_trx_plin','scr_vcnbank_rsk','scr_vcnbank_rsk_2',
                         'scr_admtcnobk1_rsk','t_rsk_maestro_score','t_mst_ctaibk_rsk',
                         't_mst_ctarcc_rsk','t_rsk_segmentacion_gdp','t_ubigeo_hist',
                         't_gdp_rcc_ppe','t_universo_rd_202603_oficial',
                         't_b39004_scr_mvpnbank_rsk_ds_scr_cal','t_edc_sd_pasiv_23_25',
                         't_ed_sd_trx_plin_vars_v2','t_ed_sd_trx_plin_vars_v2_f')
       OR table_name LIKE 't_edc_sd_bd_app_tc_nobank%'
       OR table_name LIKE 't_edc_sd_univ_altas%'
       OR table_name LIKE 'scr_vcnbank%')
ORDER BY table_schema, table_name
LIMIT 60
