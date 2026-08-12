-- ============================================================================
-- D3. MATCH DEL SCORE POR LLAVE SOLA CONTRA LLAVE MAS TIPO DE DOCUMENTO
-- ============================================================================
SELECT 'a. poblacion 202412'                                                           AS medida,
       count(*)                                                                        AS n
FROM disc_model_owner.ds_adm_vcnbank_tc_cal WHERE codmes_mrm = '202412'
UNION ALL
SELECT 'b. cruza por key_value SOLO',
       count(*)
FROM disc_model_owner.ds_adm_vcnbank_tc_cal p
INNER JOIN (SELECT DISTINCT key_value FROM e_perm_aws.scr_vcnbank_rsk WHERE p_codmes = '202412') s
        ON s.key_value = p.id_value
WHERE p.codmes_mrm = '202412'
UNION ALL
SELECT 'c. cruza por key_value MAS cod_tip_doc',
       count(*)
FROM disc_model_owner.ds_adm_vcnbank_tc_cal p
INNER JOIN (SELECT DISTINCT key_value, cod_tip_doc FROM e_perm_aws.scr_vcnbank_rsk WHERE p_codmes = '202412') s
        ON s.key_value = p.id_value AND s.cod_tip_doc = p.tip_doc
WHERE p.codmes_mrm = '202412'
UNION ALL
SELECT 'd. cruza por key_value MAS tipo casteado a entero',
       count(*)
FROM disc_model_owner.ds_adm_vcnbank_tc_cal p
INNER JOIN (SELECT DISTINCT key_value, cod_tip_doc FROM e_perm_aws.scr_vcnbank_rsk WHERE p_codmes = '202412') s
        ON s.key_value = p.id_value
       AND TRY_CAST(s.cod_tip_doc AS INTEGER) = TRY_CAST(p.tip_doc AS INTEGER)
WHERE p.codmes_mrm = '202412'
ORDER BY medida
