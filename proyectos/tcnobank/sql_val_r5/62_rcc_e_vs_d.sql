-- 62_rcc_e_vs_d.sql | las dos copias del RCC se solapan entre 201901 y 202606. Si en los mismos meses no dan lo mismo, no son la misma tabla con distinta ventana y hay que elegir cual manda antes de construir nada
SELECT esquema,
       p_codmes,
       count(*)                                                                AS n_filas,
       count(DISTINCT key_value)                                               AS clientes,
       count(DISTINCT cod_instit_financiera)                                   AS entidades,
       sum(CASE WHEN substr(cod_cuenta_rcc, 1, 2) = '81'
                 AND substr(cod_cuenta_rcc, 4, 3) = '923' THEN 1 ELSE 0 END)   AS n_linea_tc,
       round(sum(saldo) / 1000000.0, 1)                                        AS saldo_mm
FROM (
    SELECT 'd_perm_aws' AS esquema, p_codmes, key_value, cod_instit_financiera, cod_cuenta_rcc, saldo
    FROM d_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes IN ('201912', '202112', '202312', '202512')
    UNION ALL
    SELECT 'e_perm_aws', p_codmes, key_value, cod_instit_financiera, cod_cuenta_rcc, saldo
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes IN ('201912', '202112', '202312', '202512')
) x
GROUP BY esquema, p_codmes
ORDER BY p_codmes, esquema
