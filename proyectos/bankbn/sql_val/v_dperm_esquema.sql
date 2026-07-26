-- valida que d_perm_aws.t_fact_report_rcc_rsk sirva igual que e_perm (A6)
SELECT
    (SELECT COUNT(*) FROM information_schema.columns
      WHERE table_schema='d_perm_aws' AND table_name='t_fact_report_rcc_rsk'
        AND column_name IN ('codmes','tip_doc','key_value','condicion','tipo_credito',
                            'cod_cuenta_rcc','cod_instit_financiera','cod_clasificacion_deudor','saldo','p_codmes')
    ) AS cols_necesarias_de_10,
    (SELECT COUNT(*) FROM d_perm_aws.t_fact_report_rcc_rsk WHERE p_codmes='201806') AS filas_201806,
    (SELECT COUNT(*) FROM e_perm_aws.t_fact_report_rcc_rsk WHERE p_codmes='202006') AS filas_eperm_202006
