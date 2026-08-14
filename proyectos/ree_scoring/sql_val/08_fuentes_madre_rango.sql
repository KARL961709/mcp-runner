-- 08. HASTA DONDE LLEGA HOY CADA FUENTE MADRE
--   la entrega se construyo el 2026-07-27 con las coberturas declaradas en la
--   columna cobertura_declarada. Lo que avanzo desde entonces es lo que se puede
--   refrescar, y t_rsk_bkp_cierre_mensual es la que fija la frontera de madurez.
SELECT 'e_perm_aws.t_rsk_bkp_cierre_mensual'          AS fuente, 'codmes'            AS col, '201901-202606' AS cobertura_declarada, MIN(CAST(codmes AS VARCHAR))            AS cm_min, MAX(CAST(codmes AS VARCHAR))            AS cm_max FROM e_perm_aws.t_rsk_bkp_cierre_mensual
 UNION ALL
SELECT 'e_perm_aws.scr_compppibk_rsk',                     'codmes',                     '202101-202607', MIN(CAST(codmes AS VARCHAR)),                 MAX(CAST(codmes AS VARCHAR))                 FROM e_perm_aws.scr_compppibk_rsk
 UNION ALL
SELECT 'd_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp', 'codmes_desembolso',          '201901-202604', MIN(CAST(codmes_desembolso AS VARCHAR)),      MAX(CAST(codmes_desembolso AS VARCHAR))      FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp
 UNION ALL
SELECT 'e_perm_aws.t_fact_report_rcc_rsk',                 'codmes',                     '201901-202605', MIN(CAST(codmes AS VARCHAR)),                 MAX(CAST(codmes AS VARCHAR))                 FROM e_perm_aws.t_fact_report_rcc_rsk
 UNION ALL
SELECT 'e_perm_aws.ds_rtd_rskvol_cas_ingr_ir',             'periodo',                    'desde 202201',  MIN(CAST(periodo AS VARCHAR)),                MAX(CAST(periodo AS VARCHAR))                FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
 UNION ALL
SELECT 'e_perm_aws.t_rsk_cta_sueldo',                      'codmes',                     '202101-202606', MIN(CAST(codmes AS VARCHAR)),                 MAX(CAST(codmes AS VARCHAR))                 FROM e_perm_aws.t_rsk_cta_sueldo
 UNION ALL
SELECT 'e_perm_aws.t_colaboradores_gdh_rsk',               'periodo_gdh',                '201903-202401', MIN(CAST(periodo_gdh AS VARCHAR)),            MAX(CAST(periodo_gdh AS VARCHAR))            FROM e_perm_aws.t_colaboradores_gdh_rsk
