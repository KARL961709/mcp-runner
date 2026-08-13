-- ============================================================================
-- D24. CONTRATO FISICO DE LA LLAVE DE PASIVOS CONTRA LA NUESTRA
--   scan: e_perm_aws.t_aws_360_cliente_mes_d3 y ds_adm_vcnbank_tc_cal en 202412
--   ancla: R8. El create original hace CAST(cod_tipo_documento AS VARCHAR) sin que el
--          formato se haya medido de los dos lados. Nuestro tip_doc es largo 1 y valor 1
--          en el 99.3 por ciento. Un 01 contra un 1 no da error, da cero match
-- ============================================================================
SELECT medida, valor, n
FROM (
    SELECT 'A. 360 cod_tipo_documento'  AS medida,
           CAST(cod_tipo_documento AS VARCHAR)                                          AS valor,
           count(*)                                                                     AS n
    FROM e_perm_aws.t_aws_360_cliente_mes_d3
    WHERE CAST(codmes AS VARCHAR) = '202412'
    GROUP BY CAST(cod_tipo_documento AS VARCHAR)
    UNION ALL
    SELECT 'B. 360 largo de key_value', CAST(length(key_value) AS VARCHAR), count(*)
    FROM e_perm_aws.t_aws_360_cliente_mes_d3
    WHERE CAST(codmes AS VARCHAR) = '202412'
    GROUP BY length(key_value)
    UNION ALL
    SELECT 'C. po tip_doc', tip_doc, count(*)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE codmes_mrm = '202412'
    GROUP BY tip_doc
    UNION ALL
    SELECT 'D. po largo de id_value', CAST(length(id_value) AS VARCHAR), count(*)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE codmes_mrm = '202412'
    GROUP BY length(id_value)
    UNION ALL
    SELECT 'E. cruza por id_value solo', 'match', count(*)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
    INNER JOIN (SELECT DISTINCT key_value FROM e_perm_aws.t_aws_360_cliente_mes_d3
                WHERE CAST(codmes AS VARCHAR) = '202412') s ON s.key_value = c.id_value
    WHERE c.codmes_mrm = '202412'
    UNION ALL
    SELECT 'F. cruza por id_value mas tip_doc', 'match', count(*)
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
    INNER JOIN (SELECT DISTINCT key_value, CAST(cod_tipo_documento AS VARCHAR) AS tip_doc
                FROM e_perm_aws.t_aws_360_cliente_mes_d3
                WHERE CAST(codmes AS VARCHAR) = '202412') s
            ON s.key_value = c.id_value AND s.tip_doc = c.tip_doc
    WHERE c.codmes_mrm = '202412'
) z
ORDER BY medida, n DESC
LIMIT 40
