-- 2t4_j_mad_rccbwd.sql | TRAMO T4 | codmes 202312-202405 | CREATE (tmp descartable por tramo)
-- RCC pasado del titular 202212-202405 = [m0-12, m0]. A7 *_1um_m2 y Q5 *_12um_v2 caen dentro.
-- Generado por gen_tramos.py: el texto es identico entre tramos salvo los literales de mes,
-- por eso la proyeccion del INSERT INTO coincide posicionalmente con la del CREATE TABLE.
-- 20e. RCC pasado del titular (no vigente / no normal) -> disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rccbwd
--  1. Etapa 5 de 7. Ex CTE uni_mad_key, rcc_bwd, fea_rcc, rcc_titular. Ventana RCC 202106..202506.
--  2. Q5: *_12um = [m0-11, m0] (la usa flag_bpe_parcial) y *_12um_v2 = [m0-12, m0-2] (la usa 40_cal).
--  3. A7: *_1um_m2 = m0-2, paralelo a *_1um (m0). No se borra ninguna de las dos.
--  4. rcc_titular acota el LEFT JOIN a [m0-12, m0]: es el sobre de las cuatro ventanas, mismo resultado.
--  5. Grano de salida: (codmes, tip_doc, key_value).
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rccbwd AS
WITH uni_mad AS (
    SELECT DISTINCT codmes, tip_doc, key_value
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rcc
),
uni_mad_key AS (
    SELECT DISTINCT tip_doc, key_value
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rcc
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
    FROM e_perm_aws.t_fact_report_rcc_rsk a
    INNER JOIN uni_mad_key b
        ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value
    WHERE a.p_codmes BETWEEN '202212' AND '202405'
      AND a.codmes   BETWEEN '202212' AND '202405'
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
