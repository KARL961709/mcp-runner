-- 59_altas_derivadas_match.sql | la prueba definitiva: cruza fila a fila el alta derivada del RCC contra el alta oficial de tng_altas. Un solape alto habilita reconstruir la poblacion desde la madre y llegar hasta donde llegue el RCC. Un solape bajo obliga a seguir dependiendo de tng_altas y acota la serie larga
WITH tc_mes AS (
    SELECT DISTINCT tip_doc, key_value, ltrim(rtrim(cod_instit_financiera)) AS entidad
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '202404'
      AND substr(cod_cuenta_rcc, 1, 2) = '81'
      AND substr(cod_cuenta_rcc, 4, 3) = '923'
),
tc_prev AS (
    SELECT DISTINCT tip_doc, key_value, ltrim(rtrim(cod_instit_financiera)) AS entidad
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes BETWEEN '202304' AND '202403'
      AND substr(cod_cuenta_rcc, 1, 2) = '81'
      AND substr(cod_cuenta_rcc, 4, 3) = '923'
),
derivada AS (
    SELECT a.tip_doc, a.key_value, a.entidad
    FROM tc_mes a
    LEFT JOIN tc_prev b
           ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value AND a.entidad = b.entidad
    WHERE b.key_value IS NULL
),
oficial AS (
    SELECT tipdoc AS tip_doc, key_value, ltrim(rtrim(codempresa)) AS entidad
    FROM e_perm_aws.tng_altas_ssff_rsk
    WHERE p_codmes = '202404' AND ltrim(rtrim(codempresa)) <> '00002'
    UNION
    SELECT ca_tip_doc, key_value, '00002'
    FROM e_perm_aws.tng_altas_ibk_rsk
    WHERE p_codmes = '202404'
)
SELECT CASE WHEN d.key_value IS NOT NULL AND o.key_value IS NOT NULL THEN '1. en ambas'
            WHEN d.key_value IS NOT NULL                             THEN '2. solo derivada del RCC'
            ELSE                                                          '3. solo tng_altas' END AS clase,
       count(*)                                                          AS n,
       count(DISTINCT coalesce(d.entidad, o.entidad))                     AS entidades
FROM derivada d
FULL OUTER JOIN oficial o
     ON d.tip_doc = o.tip_doc AND d.key_value = o.key_value AND d.entidad = o.entidad
GROUP BY 1
ORDER BY 1
