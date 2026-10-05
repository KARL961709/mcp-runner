-- w2610_03. Maximo periodo disponible en cada fuente time-gated del build (para 202610).
--   Si el max cubre el mes requerido (col "necesita_2610"), la fuente esta lista. Read-only.
SELECT 'scr_vcbankv3_repro_opt_ (driver/pdraw)' AS fuente, CAST(MAX(p_codmes) AS varchar) AS max_periodo, '202610' AS necesita_2610 FROM disc_riesgos.scr_vcbankv3_repro_opt_
UNION ALL SELECT 'scr_vcbankv3_repro_ (no-opt, ref)', CAST(MAX(p_codmes) AS varchar), '202610' FROM disc_riesgos.scr_vcbankv3_repro_
UNION ALL SELECT 't_fact_report_rcc_rsk (RCC)', CAST(MAX(codmes) AS varchar), '202608' FROM e_perm_aws.t_fact_report_rcc_rsk
UNION ALL SELECT 't_consolidado_rsk', CAST(MAX(cons_periodo) AS varchar), '202608' FROM e_perm_aws.t_consolidado_rsk
UNION ALL SELECT 'tbl_rcc_per_allsf_mdl', CAST(MAX(codmes) AS varchar), '202608' FROM e_perm_aws.tbl_rcc_per_allsf_mdl
UNION ALL SELECT 't_rsk_rcc_stock', CAST(MAX(p_codmes) AS varchar), '202608' FROM e_perm_aws.t_rsk_rcc_stock
UNION ALL SELECT 't_agg_retail_user_trx_plin', CAST(MAX(p_codmes) AS varchar), '202609' FROM e_perm_aws.t_agg_retail_user_trx_plin
UNION ALL SELECT 't_fact_rsk_cuenta_sueldo', CAST(MAX(cod_mes) AS varchar), '202609' FROM e_perm_aws.t_fact_rsk_cuenta_sueldo
ORDER BY fuente
