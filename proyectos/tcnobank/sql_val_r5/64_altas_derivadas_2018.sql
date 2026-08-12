-- 64_altas_derivadas_2018.sql | repite la derivacion del alta sobre d_perm_aws en un mes de 2018, donde no existe tng_altas para contrastar. Se compara el ratio alta sobre stock de linea TC contra el de 202404, ya medido: si el ratio se mantiene, la derivacion se comporta igual hacia atras y la serie larga es viable
SELECT '1. alta derivada 201812'                      AS medida, count(*) AS n
FROM (
    SELECT a.tip_doc, a.key_value, a.entidad
    FROM (
        SELECT DISTINCT tip_doc, key_value, ltrim(rtrim(cod_instit_financiera)) AS entidad
        FROM d_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes = '201812'
          AND substr(cod_cuenta_rcc, 1, 2) = '81' AND substr(cod_cuenta_rcc, 4, 3) = '923'
    ) a
    LEFT JOIN (
        SELECT DISTINCT tip_doc, key_value, ltrim(rtrim(cod_instit_financiera)) AS entidad
        FROM d_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes BETWEEN '201712' AND '201811'
          AND substr(cod_cuenta_rcc, 1, 2) = '81' AND substr(cod_cuenta_rcc, 4, 3) = '923'
    ) b
      ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value AND a.entidad = b.entidad
    WHERE b.key_value IS NULL
) d
UNION ALL
SELECT '2. stock linea TC 201812', count(*)
FROM (
    SELECT DISTINCT tip_doc, key_value, ltrim(rtrim(cod_instit_financiera))
    FROM d_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '201812'
      AND substr(cod_cuenta_rcc, 1, 2) = '81' AND substr(cod_cuenta_rcc, 4, 3) = '923'
) s
UNION ALL
SELECT '3. stock linea TC 202404 (referencia)', count(*)
FROM (
    SELECT DISTINCT tip_doc, key_value, ltrim(rtrim(cod_instit_financiera))
    FROM d_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '202404'
      AND substr(cod_cuenta_rcc, 1, 2) = '81' AND substr(cod_cuenta_rcc, 4, 3) = '923'
) r
ORDER BY medida
