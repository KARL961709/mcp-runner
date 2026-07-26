-- 2t5_f_mad_rl.sql | TRAMO T5 | codmes 202406-202411 | CREATE (tmp descartable por tramo)
-- RCC del RRLL 202306-202411 = [m0-12, m0], sobre exacto de las ventanas Q5 del tramo.
-- Generado por gen_tramos.py: el texto es identico entre tramos salvo los literales de mes,
-- por eso las 7 tablas por tramo tienen proyeccion identica y el UNION ALL final cuadra.
-- 20c. RRLL: nacimiento (RENIEC) + castigo RCC 12um -> disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rl
--  1. Etapa 3 de 7. Ex CTE nacimiento_rl, uni_rl_key, fea_rcc_rl, rcc_rl, rcc_rl_titular.
--  2. fea_rcc_rl: el doble nivel del original (uni_rl_key INNER JOIN subconsulta ya filtrada por los
--     mismos docs) era redundante 1:1, se colapsa a un solo INNER JOIN. Mismo resultado.
--  3. Q5: sld_castigado_12um_rl = [m0-11, m0] (la usa flag_bpe_parcial) y _v2 = [m0-12, m0-2] (la usa 40_cal).
--  4. rcc_rl acota el LEFT JOIN a [m0-12, m0]: es el sobre de las dos ventanas, mismo resultado, sin el fan de 49 meses.
--  5. Grano de salida: (codmes, tip_doc, key_value).
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rl AS
WITH uni_rl_key AS (
    SELECT DISTINCT nrodoc_rl, tipdoc_rl
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rl_uni
),
fea_rcc_rl AS (
    SELECT
        a.codmes,
        a.key_value AS nrodoc_rl,
        a.tip_doc   AS tipdoc_rl,
        sum(CASE WHEN (substr(a.cod_cuenta_rcc,1,2)='81' AND substr(a.cod_cuenta_rcc,4,3) IN ('302','925')) THEN a.saldo ELSE null END) AS sld_castigado
    FROM e_perm_aws.t_fact_report_rcc_rsk a
    INNER JOIN uni_rl_key k
        ON a.key_value = k.nrodoc_rl AND a.tip_doc = k.tipdoc_rl
    WHERE a.p_codmes BETWEEN '202306' AND '202411'
      AND a.codmes   BETWEEN '202306' AND '202411'
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
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rl_uni a
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
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rl_uni a
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
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rl_uni a
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
