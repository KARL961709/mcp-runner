-- 81_altas_tc_completo.sql | rehace la prueba de la 58, que estaba mal: derivaba el alta usando solo la linea 81*923 e ignoraba las 30 subcuentas 14-x que la PO tambien cuenta como tarjeta. Con la definicion COMPLETA de dm_tc, el solape contra tng_altas deberia subir por encima del 96.1 por ciento medido antes
WITH tc_mes AS (
    SELECT DISTINCT tip_doc, key_value, ltrim(rtrim(cod_instit_financiera)) AS entidad
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '202404'
      AND (
            (    substr(cod_cuenta_rcc, 1, 2) = '14'
             AND tipo_credito IN ('11', '12')
             AND (   substr(cod_cuenta_rcc, 4, 7) IN ('1030201','5030201','6030201','1030202','5030202',
                                                      '6030202','1030209','5030209','6030209','5031902',
                                                      '1030203','5030203','6030203','1030613','4030613',
                                                      '5030613','6030613','5031908','6031908','5031998','6031998')
                  OR substr(cod_cuenta_rcc, 4, 5) IN ('10304','40304','50304','60304','40302',
                                                      '10308','40308','50308','60308') ) )
         OR (substr(cod_cuenta_rcc, 1, 2) = '81' AND substr(cod_cuenta_rcc, 4, 3) = '923')
          )
),
tc_prev AS (
    SELECT DISTINCT tip_doc, key_value, ltrim(rtrim(cod_instit_financiera)) AS entidad
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes BETWEEN '202304' AND '202403'
      AND (
            (    substr(cod_cuenta_rcc, 1, 2) = '14'
             AND tipo_credito IN ('11', '12')
             AND (   substr(cod_cuenta_rcc, 4, 7) IN ('1030201','5030201','6030201','1030202','5030202',
                                                      '6030202','1030209','5030209','6030209','5031902',
                                                      '1030203','5030203','6030203','1030613','4030613',
                                                      '5030613','6030613','5031908','6031908','5031998','6031998')
                  OR substr(cod_cuenta_rcc, 4, 5) IN ('10304','40304','50304','60304','40302',
                                                      '10308','40308','50308','60308') ) )
         OR (substr(cod_cuenta_rcc, 1, 2) = '81' AND substr(cod_cuenta_rcc, 4, 3) = '923')
          )
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
       count(*)                                       AS n,
       count(DISTINCT coalesce(d.entidad, o.entidad)) AS entidades
FROM derivada d
FULL OUTER JOIN oficial o
     ON d.tip_doc = o.tip_doc AND d.key_value = o.key_value AND d.entidad = o.entidad
GROUP BY 1
ORDER BY 1
