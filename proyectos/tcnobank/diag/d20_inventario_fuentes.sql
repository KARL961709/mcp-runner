-- ============================================================================
-- D20. QUE EXISTE Y ES ALCANZABLE DESDE ATHENA
--   scan: information_schema.tables de los cuatro esquemas
--   ancla: la tabla de nodos ya construida vive en datalab_risk_people_banking, que
--          nunca consultamos. Si es alcanzable no hay que reproducir la logica
-- ============================================================================
SELECT table_schema,
       table_name,
       table_type
FROM information_schema.tables
WHERE (    table_schema IN ('e_perm_aws','d_perm_aws','datalab_risk_people_banking')
       AND (   table_name IN ('t_agg_retail_user_trx_plin','scr_vcnbank_rsk','scr_vcnbank_rsk_2',
                              'scr_admtcnobk1_rsk','t_rsk_maestro_score','t_mst_ctaibk_rsk',
                              't_aws_360_cliente_mes_d3','t_fact_edc_solicitud_retiro_afp_ibk',
                              't_edc_sd_pasiv_23_25','t_ed_sd_trx_plin_vars_v2',
                              't_b39004_scr_mvpnbank_rsk_ds_scr_cal')
            OR table_name LIKE 't_edc_sd_bd_app_tc_nobank%'
            OR table_name LIKE 'scr_vcnbank%'
            OR table_name LIKE '%retiro_afp%'))
   OR (table_schema = 'disc_model_owner' AND lower(table_name) LIKE '%pasivos%')
ORDER BY table_schema, table_name
LIMIT 60
