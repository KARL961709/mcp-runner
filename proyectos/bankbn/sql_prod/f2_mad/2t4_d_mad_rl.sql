-- 2t4_d_mad_rl.sql | representantes legales nacimiento y castigo | escribe 202204-202308 lee 202104-202308
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rl_t4 AS
WITH rl_uni AS (
    SELECT
        b.codmes,
        b.key_value,
        b.tip_doc,
        a.key_value AS nrodoc_rl,
        a.tip_doc   AS tipdoc_rl
    FROM e_perm_aws.t_mst_rep_legal_sunat_rsk a
    INNER JOIN (
        SELECT DISTINCT codmes, tip_doc, key_value
        FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rcc_t4
    ) b
        ON a.ruc_value = b.key_value
       AND cast(date_format(date_parse(cast(a.fec_vigencia AS varchar),'%Y-%m-%d'), '%Y%m') AS int) <= cast(b.codmes AS int)
    GROUP BY b.codmes, b.key_value, b.tip_doc, a.key_value, a.tip_doc
),
uni_rl_key AS (
    SELECT DISTINCT nrodoc_rl, tipdoc_rl
    FROM rl_uni
),
fea_rcc_rl AS (
    SELECT
        a.codmes,
        a.key_value AS nrodoc_rl,
        a.tip_doc   AS tipdoc_rl,
        sum(CASE WHEN (substr(a.cod_cuenta_rcc,1,2)='81' AND substr(a.cod_cuenta_rcc,4,3) IN ('302','925')) THEN a.saldo ELSE null END) AS sld_castigado
    FROM (
        SELECT codmes, tip_doc, key_value, cod_cuenta_rcc, saldo
        FROM e_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes BETWEEN '202104' AND '202308'
          AND codmes   BETWEEN '202104' AND '202308'
    ) a
    INNER JOIN uni_rl_key k
        ON a.key_value = k.nrodoc_rl AND a.tip_doc = k.tipdoc_rl
    GROUP BY a.codmes, a.key_value, a.tip_doc
),
rcc_rl AS (
    SELECT
        a.codmes,
        a.tipdoc_rl,
        a.nrodoc_rl,
        sum(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') - interval '11' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') - interval '0'  month,'%Y%m') THEN b.sld_castigado ELSE null END) AS sld_castigado_12um_rl,
        sum(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') - interval '12' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') - interval '2'  month,'%Y%m') THEN b.sld_castigado ELSE null END) AS sld_castigado_12um_rl_v2
    FROM rl_uni a
    LEFT JOIN fea_rcc_rl b
        ON a.nrodoc_rl = b.nrodoc_rl AND a.tipdoc_rl = b.tipdoc_rl
       AND b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') - interval '12' month,'%Y%m')
                        AND date_format(date_parse(a.codmes,'%Y%m') - interval '0'  month,'%Y%m')
    GROUP BY a.codmes, a.nrodoc_rl, a.tipdoc_rl
),
rcc_rl_titular AS (
    SELECT
        a.codmes,
        a.tip_doc,
        a.key_value,
        sum(b.sld_castigado_12um_rl)    AS sld_castigado_12um_rl,
        sum(b.sld_castigado_12um_rl_v2) AS sld_castigado_12um_rl_v2
    FROM rl_uni a
    LEFT JOIN rcc_rl b
        ON a.codmes = b.codmes AND a.tipdoc_rl = b.tipdoc_rl AND a.nrodoc_rl = b.nrodoc_rl
    GROUP BY a.codmes, a.tip_doc, a.key_value
),
nacimiento_rl AS (
    SELECT
        a.codmes,
        a.key_value,
        a.tip_doc,
        min(c.fec_nacimiento) AS fec_nacimiento_rl_min,
        max(c.fec_nacimiento) AS fec_nacimiento_rl_max
    FROM rl_uni a
    LEFT JOIN e_perm_aws.t_mst_reniec_rsk c
        ON a.nrodoc_rl = c.key_value AND a.tipdoc_rl = c.tip_doc
    GROUP BY 1,2,3
)
SELECT
    a.codmes,
    a.tip_doc,
    a.key_value,
    a.fec_nacimiento_rl_min,
    a.fec_nacimiento_rl_max,
    b.sld_castigado_12um_rl,
    b.sld_castigado_12um_rl_v2
FROM nacimiento_rl a
LEFT JOIN rcc_rl_titular b
    ON a.codmes = b.codmes AND a.tip_doc = b.tip_doc AND a.key_value = b.key_value
