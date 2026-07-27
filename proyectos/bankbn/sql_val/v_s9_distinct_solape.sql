-- v_s9_distinct_solape.sql | el SELECT DISTINCT colapsa el solape? si filas_distinct < filas_union hay duplicacion real
WITH u AS (
    SELECT codmes, tip_doc, key_value, condicion, tipo_credito, cod_cuenta_rcc,
           cod_instit_financiera, cod_clasificacion_deudor, saldo
    FROM d_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '201903'
    UNION ALL
    SELECT codmes, tip_doc, key_value, condicion, tipo_credito, cod_cuenta_rcc,
           cod_instit_financiera, cod_clasificacion_deudor, saldo
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '201903'
)
SELECT 'UNION_ALL' AS modo, count(1) AS filas, sum(saldo) AS saldo
FROM u
UNION ALL
SELECT 'DISTINCT', count(1), sum(saldo)
FROM (SELECT DISTINCT * FROM u) d
