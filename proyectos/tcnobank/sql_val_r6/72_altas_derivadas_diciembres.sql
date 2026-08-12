-- 72_altas_derivadas_diciembres.sql | corrige la comparacion de la 64, que enfrentaba diciembre 2018 contra abril 2024 y mezclaba estacionalidad con deriva. Aca los dos son diciembre, asi que el ratio alta sobre stock es comparable y dice si la derivacion se comporta igual hacia atras
SELECT '1. alta derivada 202312'   AS medida, count(*) AS n
FROM (
    SELECT a.tip_doc, a.key_value, a.entidad
    FROM (
        SELECT DISTINCT tip_doc, key_value, ltrim(rtrim(cod_instit_financiera)) AS entidad
        FROM d_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes = '202312'
          AND substr(cod_cuenta_rcc, 1, 2) = '81' AND substr(cod_cuenta_rcc, 4, 3) = '923'
    ) a
    LEFT JOIN (
        SELECT DISTINCT tip_doc, key_value, ltrim(rtrim(cod_instit_financiera)) AS entidad
        FROM d_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes BETWEEN '202212' AND '202311'
          AND substr(cod_cuenta_rcc, 1, 2) = '81' AND substr(cod_cuenta_rcc, 4, 3) = '923'
    ) b
      ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value AND a.entidad = b.entidad
    WHERE b.key_value IS NULL
) d
UNION ALL
SELECT '2. stock linea TC 202312', count(*)
FROM (
    SELECT DISTINCT tip_doc, key_value, ltrim(rtrim(cod_instit_financiera))
    FROM d_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '202312'
      AND substr(cod_cuenta_rcc, 1, 2) = '81' AND substr(cod_cuenta_rcc, 4, 3) = '923'
) s
ORDER BY medida
