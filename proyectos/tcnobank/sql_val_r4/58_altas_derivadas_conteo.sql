-- 58_altas_derivadas_conteo.sql | prueba de viabilidad: deriva el alta de TC del propio RCC (linea 81*923 presente en el mes y ausente en los 12 previos) y la contrasta en volumen contra las dos tablas de altas para el mismo mes. Si los ordenes de magnitud coinciden, la poblacion se puede reconstruir sin depender de tng_altas y hereda toda la profundidad del RCC
SELECT '1. derivada del RCC (linea TC nueva)' AS fuente,
       count(*)                               AS n
FROM (
    SELECT a.tip_doc, a.key_value, a.cod_instit_financiera
    FROM (
        SELECT DISTINCT tip_doc, key_value, ltrim(rtrim(cod_instit_financiera)) AS cod_instit_financiera
        FROM e_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes = '202404'
          AND substr(cod_cuenta_rcc, 1, 2) = '81'
          AND substr(cod_cuenta_rcc, 4, 3) = '923'
    ) a
    LEFT JOIN (
        SELECT DISTINCT tip_doc, key_value, ltrim(rtrim(cod_instit_financiera)) AS cod_instit_financiera
        FROM e_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes BETWEEN '202304' AND '202403'
          AND substr(cod_cuenta_rcc, 1, 2) = '81'
          AND substr(cod_cuenta_rcc, 4, 3) = '923'
    ) b
      ON a.tip_doc = b.tip_doc
     AND a.key_value = b.key_value
     AND a.cod_instit_financiera = b.cod_instit_financiera
    WHERE b.key_value IS NULL
) d
UNION ALL
SELECT '2. tng_altas_ssff_rsk (sin 00002)', count(*)
FROM e_perm_aws.tng_altas_ssff_rsk
WHERE p_codmes = '202404' AND ltrim(rtrim(codempresa)) <> '00002'
UNION ALL
SELECT '3. tng_altas_ibk_rsk', count(*)
FROM e_perm_aws.tng_altas_ibk_rsk
WHERE p_codmes = '202404'
UNION ALL
SELECT '4. linea TC viva en el mes (denominador)', count(*)
FROM (
    SELECT DISTINCT tip_doc, key_value, ltrim(rtrim(cod_instit_financiera))
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '202404'
      AND substr(cod_cuenta_rcc, 1, 2) = '81'
      AND substr(cod_cuenta_rcc, 4, 3) = '923'
) v
ORDER BY fuente
