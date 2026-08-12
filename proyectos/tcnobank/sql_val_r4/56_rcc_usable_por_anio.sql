-- 56_rcc_usable_por_anio.sql | un diciembre por anio para confirmar que el RCC no solo existe sino que sirve: que traiga linea de tarjeta, mora y clasificacion pobladas. Una particion por anio, no la serie entera
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
       sum(CASE WHEN cod_clasificacion_deudor IS NULL THEN 1 ELSE 0 END)                 AS sin_clasif
FROM e_perm_aws.t_fact_report_rcc_rsk
WHERE p_codmes IN ('201612', '201712', '201812', '201912', '202012',
                   '202112', '202212', '202312', '202412', '202512')
GROUP BY p_codmes
ORDER BY p_codmes
