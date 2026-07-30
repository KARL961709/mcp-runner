-- s02 COBERTURA de t_rm_direccion_estandarizada sobre las dos poblaciones
--     puente codunico -> cuc_num -> key_value via t_dim_cliente (13.98M personas, mejor que apicliente)
WITH rm AS (
  SELECT DISTINCT trim(codunico) AS codunico
  FROM d_perm_aws.t_rm_direccion_estandarizada
  WHERE codunico IS NOT NULL AND trim(codunico) <> ''
),
dc AS (
  SELECT DISTINCT trim(cuc_num) AS cuc_num, key_value
  FROM e_perm_aws.t_dim_cliente
  WHERE tipo_persona_host = '01' AND cuc_num IS NOT NULL AND trim(cuc_num) <> ''
),
pers AS (
  SELECT DISTINCT dc.key_value FROM rm JOIN dc ON dc.cuc_num = rm.codunico
),
adm AS (SELECT DISTINCT key_value FROM d_perm_aws.scr_vcadmbnk_hist_rsk WHERE p_codmes = '202607'),
stk AS (SELECT DISTINCT key_value FROM e_perm_aws.scr_vcclibnk_rsk WHERE p_codmes = '202607')
SELECT 'estandarizada' AS tabla,
       (SELECT count(*) FROM rm)                                                  AS codunicos_en_rm,
       (SELECT count(*) FROM pers)                                                AS personas_puenteadas,
       (SELECT count(*) FROM pers JOIN adm ON adm.key_value = pers.key_value)      AS inter_admision,
       (SELECT count(*) FROM pers JOIN stk ON stk.key_value = pers.key_value)      AS inter_stock,
       round(100.0 * (SELECT count(*) FROM pers JOIN adm ON adm.key_value = pers.key_value)
                   / (SELECT count(*) FROM adm), 2)                               AS pct_admision,
       round(100.0 * (SELECT count(*) FROM pers JOIN stk ON stk.key_value = pers.key_value)
                   / (SELECT count(*) FROM stk), 2)                               AS pct_stock
