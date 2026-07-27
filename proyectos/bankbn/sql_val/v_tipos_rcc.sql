-- compara tipos de columna entre d_perm y e_perm del RCC
SELECT column_name,
       max(CASE WHEN table_schema='d_perm_aws' THEN data_type END) AS tipo_dperm,
       max(CASE WHEN table_schema='e_perm_aws' THEN data_type END) AS tipo_eperm
FROM information_schema.columns
WHERE table_name='t_fact_report_rcc_rsk'
  AND table_schema IN ('d_perm_aws','e_perm_aws')
  AND column_name IN ('codmes','p_codmes','tip_doc','key_value','condicion','tipo_credito',
                      'cod_cuenta_rcc','cod_instit_financiera','cod_clasificacion_deudor','saldo')
GROUP BY column_name
ORDER BY column_name
