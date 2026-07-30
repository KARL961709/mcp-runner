-- r03 COBERTURA de t_rm_direccion_estandarizada sobre las dos poblaciones
--     asume key_value (llave estandar del banco). Si falla, r01 dice el nombre real de la llave
WITH e AS (SELECT DISTINCT key_value FROM d_perm_aws.t_rm_direccion_estandarizada),
adm AS (SELECT DISTINCT key_value FROM d_perm_aws.scr_vcadmbnk_hist_rsk WHERE p_codmes = '202607'),
stk AS (SELECT DISTINCT key_value FROM e_perm_aws.scr_vcclibnk_rsk WHERE p_codmes = '202607')
SELECT (SELECT count(*) FROM e)                                          AS personas_en_tabla,
       (SELECT count(*) FROM e JOIN adm ON adm.key_value = e.key_value)  AS inter_admision,
       (SELECT count(*) FROM e JOIN stk ON stk.key_value = e.key_value)  AS inter_stock,
       round(100.0 * (SELECT count(*) FROM e JOIN adm ON adm.key_value = e.key_value)
                   / (SELECT count(*) FROM adm), 2)                      AS pct_admision,
       round(100.0 * (SELECT count(*) FROM e JOIN stk ON stk.key_value = e.key_value)
                   / (SELECT count(*) FROM stk), 2)                      AS pct_stock
