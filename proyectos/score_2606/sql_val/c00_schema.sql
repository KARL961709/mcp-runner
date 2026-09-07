-- c00. Schema de las fuentes raw: confirma la columna de periodo/llave real (no escanea datos).
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws'
  AND table_name IN ('t_fact_rsk_cuenta_sueldo','t_rsk_rcc_stock','tbl_rcc_per_allsf_mdl',
                     'ds_rtd_rskvol_cas_ingr_ir','t_agg_retail_user_trx_plin','t_fact_report_rcc_rsk',
                     't_sunarp_inmueble','t_maestra_profesiones','t_mst_ctarcc_rsk')
  AND (column_name LIKE '%mes%' OR column_name LIKE '%eriodo%' OR column_name LIKE '%fec%'
       OR column_name LIKE '%key%' OR column_name LIKE '%sbs%' OR column_name LIKE '%cif%')
ORDER BY table_name, column_name
