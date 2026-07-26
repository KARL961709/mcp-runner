-- b2 FUENTE: RCC accesible con poda
SELECT COUNT(*) AS n
FROM (SELECT codmes FROM e_perm_aws.t_fact_report_rcc_rsk WHERE p_codmes = '202405' LIMIT 100) t
