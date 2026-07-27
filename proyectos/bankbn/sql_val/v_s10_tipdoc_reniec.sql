-- v_s10_tipdoc_reniec.sql | dominio de tip_doc en RENIEC vs RCC: decide si el join crudo de fec_nacimiento pega
SELECT fuente,
       tip_doc,
       length(tip_doc)           AS largo,
       count(1)                  AS filas,
       count(DISTINCT key_value) AS llaves
FROM (
    SELECT 'RENIEC' AS fuente, tip_doc, key_value
    FROM e_perm_aws.t_mst_reniec_rsk
    UNION ALL
    SELECT 'RCC_EPERM', tip_doc, key_value
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '202506'
) u
GROUP BY fuente, tip_doc, length(tip_doc)
ORDER BY fuente, tip_doc
