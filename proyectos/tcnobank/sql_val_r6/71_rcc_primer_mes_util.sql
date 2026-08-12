-- 71_rcc_primer_mes_util.sql | fija el primer mes con DATOS del RCC. La metadata de particiones declara 201405 pero 201412, 201512 y 201612 vinieron vacios, asi que hay particiones registradas sin contenido y el arranque real hay que medirlo mes a mes
SELECT p_codmes,
       count(*)                                                                        AS n_filas,
       count(DISTINCT key_value)                                                       AS clientes,
       count(DISTINCT cod_instit_financiera)                                           AS entidades,
       sum(CASE WHEN substr(cod_cuenta_rcc, 1, 2) = '81'
                 AND substr(cod_cuenta_rcc, 4, 3) = '923' THEN 1 ELSE 0 END)           AS n_linea_tc
FROM d_perm_aws.t_fact_report_rcc_rsk
WHERE p_codmes BETWEEN '201601' AND '201806'
GROUP BY p_codmes
ORDER BY p_codmes
