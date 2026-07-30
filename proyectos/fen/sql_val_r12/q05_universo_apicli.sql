-- q05 EL TECHO DE APICLIENTE -- cuantas personas contiene en total y cuantas comparte con cada poblacion
--     si el universo es 6.6M, admision (13.0M) no puede pasar de ~51% por construccion
WITH a AS (SELECT DISTINCT key_value FROM d_perm_aws.t_dmdireccion_apicliente),
adm AS (SELECT DISTINCT key_value FROM d_perm_aws.scr_vcadmbnk_hist_rsk WHERE p_codmes = '202607'),
stk AS (SELECT DISTINCT key_value FROM e_perm_aws.scr_vcclibnk_rsk WHERE p_codmes = '202607')
SELECT (SELECT count(*) FROM a)                                              AS personas_en_apicliente,
       (SELECT count(*) FROM adm)                                            AS personas_admision,
       (SELECT count(*) FROM stk)                                            AS personas_stock,
       (SELECT count(*) FROM a JOIN adm ON adm.key_value = a.key_value)      AS apicli_inter_admision,
       (SELECT count(*) FROM a JOIN stk ON stk.key_value = a.key_value)      AS apicli_inter_stock,
       (SELECT count(*) FROM a WHERE a.key_value NOT IN (SELECT key_value FROM adm)
                                 AND a.key_value NOT IN (SELECT key_value FROM stk)) AS apicli_fuera_de_ambas
