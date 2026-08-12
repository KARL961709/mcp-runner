-- 57_formato_llaves.sql | mide el formato de las DOS llaves antes de cruzar RCC contra altas. Un largo distinto o ceros a la izquierda hacen que el cruce devuelva vacio sin dar error, y el diagnostico se paga en otro viaje
SELECT campo, largo, count(*) AS n
FROM (
    SELECT 'A.rcc.cod_instit_financiera' AS campo, length(cod_instit_financiera) AS largo
    FROM e_perm_aws.t_fact_report_rcc_rsk WHERE p_codmes = '202404'
    UNION ALL
    SELECT 'B.ssff.codempresa', length(codempresa)
    FROM e_perm_aws.tng_altas_ssff_rsk WHERE p_codmes = '202404'
    UNION ALL
    SELECT 'C.rcc.key_value', length(key_value)
    FROM e_perm_aws.t_fact_report_rcc_rsk WHERE p_codmes = '202404'
    UNION ALL
    SELECT 'D.ssff.key_value', length(key_value)
    FROM e_perm_aws.tng_altas_ssff_rsk WHERE p_codmes = '202404'
    UNION ALL
    SELECT 'E.ibk.key_value', length(key_value)
    FROM e_perm_aws.tng_altas_ibk_rsk WHERE p_codmes = '202404'
    UNION ALL
    SELECT 'F.rcc.tip_doc', length(tip_doc)
    FROM e_perm_aws.t_fact_report_rcc_rsk WHERE p_codmes = '202404'
    UNION ALL
    SELECT 'G.ssff.tipdoc', length(tipdoc)
    FROM e_perm_aws.tng_altas_ssff_rsk WHERE p_codmes = '202404'
) x
GROUP BY campo, largo
ORDER BY campo, largo
