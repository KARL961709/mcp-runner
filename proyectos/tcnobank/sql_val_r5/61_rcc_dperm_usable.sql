-- 61_rcc_dperm_usable.sql | confirma que el RCC de d_perm_aws no solo existe desde 201405 sino que sirve en los anios viejos: linea de tarjeta presente, mora y clasificacion pobladas, entidades en volumen razonable. Un diciembre por anio
SELECT p_codmes,
       count(*)                                                                          AS n_filas,
       count(DISTINCT key_value)                                                         AS clientes,
       count(DISTINCT cod_instit_financiera)                                             AS entidades,
       sum(CASE WHEN substr(cod_cuenta_rcc, 1, 2) = '81'
                 AND substr(cod_cuenta_rcc, 4, 3) = '923' THEN 1 ELSE 0 END)             AS n_linea_tc,
       count(DISTINCT CASE WHEN substr(cod_cuenta_rcc, 1, 2) = '81'
                            AND substr(cod_cuenta_rcc, 4, 3) = '923'
                           THEN key_value END)                                           AS clientes_con_tc,
       sum(CASE WHEN condicion IS NULL THEN 1 ELSE 0 END)                                AS sin_condicion,
       sum(CASE WHEN cod_clasificacion_deudor IS NULL THEN 1 ELSE 0 END)                 AS sin_clasif,
       sum(CASE WHEN saldo IS NULL THEN 1 ELSE 0 END)                                    AS sin_saldo
FROM d_perm_aws.t_fact_report_rcc_rsk
WHERE p_codmes IN ('201412', '201512', '201612', '201712', '201812', '201912', '202012')
GROUP BY p_codmes
ORDER BY p_codmes
