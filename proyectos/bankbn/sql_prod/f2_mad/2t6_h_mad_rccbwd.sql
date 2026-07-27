-- 2t6_h_mad_rccbwd.sql | rcc pasado del titular | escribe 202506-202606 lee 202406-202606
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rccbwd_t6 AS
WITH uni_mad AS (
    SELECT DISTINCT codmes, tip_doc, key_value
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rcc_t6
),
uni_mad_key AS (
    SELECT DISTINCT tip_doc, key_value
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rcc_t6
),
rcc_bwd AS (
    SELECT
        a.codmes,
        a.tip_doc,
        a.key_value,
        a.tipo_credito,
        a.cod_cuenta_rcc,
        a.cod_clasificacion_deudor,
        a.saldo
    FROM (
        SELECT codmes, tip_doc, key_value, tipo_credito, cod_cuenta_rcc, cod_clasificacion_deudor, saldo
        FROM e_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes BETWEEN '202404' AND '202608'
          AND codmes   BETWEEN '202406' AND '202606'
    ) a
    INNER JOIN uni_mad_key b
        ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value
),
fea_rcc AS (
    SELECT
        codmes,
        key_value,
        tip_doc,
        sum(CASE WHEN (substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,7,2) NOT IN ('01','04')) AND substr(cod_cuenta_rcc,4,1) IN ('3','4','5','6')
                  AND tipo_credito IN ('01','02','03','04','05','06','07','08','09','10') THEN saldo ELSE null END) AS saldo_novig_neg,
        sum(CASE WHEN (substr(cod_cuenta_rcc,1,2)='14') AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')
                  AND cod_clasificacion_deudor <> '0' AND substr(cod_cuenta_rcc,7,2) NOT IN ('01','04') THEN saldo ELSE null END) AS sld_no_normal
    FROM rcc_bwd
    GROUP BY codmes, key_value, tip_doc
)
SELECT
    a.codmes,
    a.tip_doc,
    a.key_value,
    sum(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') - interval '11' month,'%Y%m')
                               AND date_format(date_parse(a.codmes,'%Y%m') - interval '0'  month,'%Y%m') THEN b.saldo_novig_neg ELSE null END) AS saldo_novig_neg_12um,
    sum(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') - interval '12' month,'%Y%m')
                               AND date_format(date_parse(a.codmes,'%Y%m') - interval '2'  month,'%Y%m') THEN b.saldo_novig_neg ELSE null END) AS saldo_novig_neg_12um_v2,
    sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') - interval '0' month,'%Y%m') THEN b.saldo_novig_neg ELSE null END) AS saldo_novig_neg_1um,
    sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') - interval '2' month,'%Y%m') THEN b.saldo_novig_neg ELSE null END) AS saldo_novig_neg_1um_m2,
    sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') - interval '0' month,'%Y%m') THEN b.sld_no_normal   ELSE null END) AS saldo_nonormal_1um,
    sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') - interval '2' month,'%Y%m') THEN b.sld_no_normal   ELSE null END) AS saldo_nonormal_1um_m2
FROM uni_mad a
LEFT JOIN fea_rcc b
    ON a.key_value = b.key_value AND a.tip_doc = b.tip_doc
   AND b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') - interval '12' month,'%Y%m')
                    AND date_format(date_parse(a.codmes,'%Y%m') - interval '0'  month,'%Y%m')
GROUP BY a.codmes, a.tip_doc, a.key_value
