-- r04 COBERTURA de t_mst_ccd_direccion sobre las dos poblaciones
WITH c AS (SELECT DISTINCT key_value FROM d_perm_aws.t_mst_ccd_direccion),
adm AS (SELECT DISTINCT key_value FROM d_perm_aws.scr_vcadmbnk_hist_rsk WHERE p_codmes = '202607'),
stk AS (SELECT DISTINCT key_value FROM e_perm_aws.scr_vcclibnk_rsk WHERE p_codmes = '202607')
SELECT (SELECT count(*) FROM c)                                          AS personas_en_tabla,
       (SELECT count(*) FROM c JOIN adm ON adm.key_value = c.key_value)  AS inter_admision,
       (SELECT count(*) FROM c JOIN stk ON stk.key_value = c.key_value)  AS inter_stock,
       round(100.0 * (SELECT count(*) FROM c JOIN adm ON adm.key_value = c.key_value)
                   / (SELECT count(*) FROM adm), 2)                      AS pct_admision,
       round(100.0 * (SELECT count(*) FROM c JOIN stk ON stk.key_value = c.key_value)
                   / (SELECT count(*) FROM stk), 2)                      AS pct_stock
