-- 2t6_b_mad_rcc.sql | rcc futuro y pivot ventanas | escribe 202506-202606 lee 202504-202606
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rcc_t6 AS
WITH uni AS (
    SELECT
        codmes,
        tip_doc,
        key_value,
        cod_instit_financiera AS ent_alta,
        cod_instit_financiera,
        nombre_instit_financiera
    FROM disc_model_owner.ds_adm_bpe_bankbn_po
    WHERE codmes BETWEEN '202506' AND '202606'
      AND ((30000 <= max_saldo AND (saldo_m0 >= 10000 AND saldo_m0 < 30000)) OR (saldo_m0 >= 30000))
),
uni_key AS (
    SELECT DISTINCT tip_doc, key_value FROM uni
),
rcc_fwd AS (
    SELECT DISTINCT
        a.codmes,
        a.tip_doc,
        a.key_value,
        a.condicion,
        a.tipo_credito,
        a.cod_cuenta_rcc,
        a.cod_instit_financiera,
        a.cod_clasificacion_deudor,
        a.saldo
    FROM (
        SELECT codmes, tip_doc, key_value, condicion, tipo_credito, cod_cuenta_rcc,
               cod_instit_financiera, cod_clasificacion_deudor, saldo
        FROM e_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes BETWEEN '202504' AND '202606'
          AND codmes   BETWEEN '202504' AND '202606'
    ) a
    INNER JOIN uni_key b
        ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value
),
data_rcc AS (
    SELECT
        codmes,
        tip_doc,
        key_value,
        cod_instit_financiera,
        sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 AND (substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6'))
                 THEN saldo ELSE 0 END) AS saldo_mo,
        sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 AND ((substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6'))
                   OR (substr(cod_cuenta_rcc,1,2)='81' AND substr(cod_cuenta_rcc,4,3) IN ('302','925')))
                 THEN saldo ELSE null END) AS saldo_total,
        sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 AND (substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,4,1) IN ('4'))
                 THEN saldo ELSE null END) AS sald_ref_mo,
        sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 11 AND 13 THEN saldo ELSE null END) AS sld_cons,
        sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 AND (substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,4,1) IN ('6'))
                 THEN saldo ELSE null END) AS sald_jud_mo,
        sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 AND (substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,4,1) IN ('3'))
                 THEN saldo ELSE null END) AS sald_rest_mo,
        sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 AND substr(cod_cuenta_rcc,1,2)='81' AND substr(cod_cuenta_rcc,4,3) IN ('302','925')
                 THEN saldo ELSE null END) AS sald_cast_mo,
        max(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 AND (substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,7,2) NOT IN ('01','04') AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6'))
                 THEN cod_clasificacion_deudor ELSE null END) AS clasif_mo,
        max(CASE WHEN (cast(tipo_credito AS int) BETWEEN 1 AND 10 AND (substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,7,2) NOT IN ('01','04') AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')))
                   OR (substr(cod_cuenta_rcc,1,2)='81' AND (cast(tipo_credito AS int) BETWEEN 1 AND 10) AND substr(cod_cuenta_rcc,4,3)='925')
                   OR (substr(cod_cuenta_rcc,1,2)='81' AND (cast(tipo_credito AS int) BETWEEN 1 AND 10) AND substr(cod_cuenta_rcc,4,3)='302')
                 THEN condicion ELSE null END) AS dm,
        sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 AND regexp_like(cod_cuenta_rcc, '^84.40[12345]') THEN saldo ELSE 0 END) AS garp_p,
        sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 AND regexp_like(cod_cuenta_rcc, '^84.4(09|10)')  THEN saldo ELSE 0 END) AS garp_np,
        max(CASE WHEN substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,4,1)='3' AND tipo_credito IN ('01','02','03','04','05','06','07','08','09','10') THEN 1 ELSE 0 END) AS flag_ref_ree,
        max(CASE WHEN substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,4,1)='4' AND tipo_credito IN ('01','02','03','04','05','06','07','08','09','10') THEN 1 ELSE 0 END) AS flag_ref,
        max(CASE WHEN substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,4,1)='5' AND tipo_credito IN ('01','02','03','04','05','06','07','08','09','10') THEN 1 ELSE 0 END) AS flag_ven,
        max(CASE WHEN substr(cod_cuenta_rcc,1,2)='14' AND substr(cod_cuenta_rcc,4,1)='6' AND tipo_credito IN ('01','02','03','04','05','06','07','08','09','10') THEN 1 ELSE 0 END) AS flag_jud,
        max(CASE WHEN substr(cod_cuenta_rcc,1,2)='81' AND substr(cod_cuenta_rcc,4,3) IN ('302','925') AND tipo_credito IN ('01','02','03','04','05','06','07','08','09','10') THEN 1 ELSE 0 END) AS flag_cast,
        sum(CASE WHEN substr(cod_cuenta_rcc,1,2)='81' AND substr(cod_cuenta_rcc,4,1)='8' AND substr(cod_cuenta_rcc,6,1) IN ('1','3','4','5','6') THEN saldo ELSE 0 END) AS sld_reactiva
    FROM rcc_fwd
    GROUP BY codmes, tip_doc, key_value, cod_instit_financiera
),
info_consolid AS (
    SELECT
        a.codmes,
        a.tip_doc,
        a.key_value,
        a.ent_alta,
        a.cod_instit_financiera,
        a.nombre_instit_financiera,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '0' month,'%Y%m') THEN b.saldo_mo      ELSE 0    END) AS saldo_vig_m0,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '0' month,'%Y%m') THEN b.sld_cons     ELSE 0    END) AS sld_cons_m0,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '0' month,'%Y%m') THEN b.sald_ref_mo  ELSE null END) AS saldo_ref_m0,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '0' month,'%Y%m') THEN b.sald_jud_mo  ELSE null END) AS saldo_jud_mo,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '0' month,'%Y%m') THEN b.sald_cast_mo ELSE null END) AS saldo_cast_mo,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '0' month,'%Y%m') THEN b.sald_rest_mo ELSE null END) AS saldo_rest_mo,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '0' month,'%Y%m') THEN b.garp_p       ELSE 0    END) AS saldo_gar_p,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '0' month,'%Y%m') THEN b.garp_np      ELSE 0    END) AS saldo_gar_np,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '0' month,'%Y%m') THEN b.clasif_mo    ELSE null END) AS clasificacion_m0,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '0' month,'%Y%m') THEN b.dm           ELSE 0    END) AS dm_fm0,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '0' month,'%Y%m') THEN b.sld_reactiva ELSE 0    END) AS sld_reactiva,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') - interval '2' month,'%Y%m') THEN b.saldo_mo      ELSE 0    END) AS saldo_vig_m2,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') - interval '2' month,'%Y%m') THEN b.sald_ref_mo  ELSE null END) AS saldo_ref_m2,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') - interval '2' month,'%Y%m') THEN b.sald_jud_mo  ELSE null END) AS saldo_jud_m2,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') - interval '2' month,'%Y%m') THEN b.sald_cast_mo ELSE null END) AS saldo_cast_m2,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') - interval '2' month,'%Y%m') THEN b.sald_rest_mo ELSE null END) AS saldo_rest_m2,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') - interval '2' month,'%Y%m') THEN b.clasif_mo    ELSE null END) AS clasificacion_m2,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') - interval '2' month,'%Y%m') THEN b.dm           ELSE 0    END) AS dm_org_m2,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '1'  month,'%Y%m') AND b.cod_instit_financiera = a.ent_alta THEN b.dm ELSE 0 END) AS dm_fm1,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '2'  month,'%Y%m') AND b.cod_instit_financiera = a.ent_alta THEN b.dm ELSE 0 END) AS dm_fm2,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '3'  month,'%Y%m') AND b.cod_instit_financiera = a.ent_alta THEN b.dm ELSE 0 END) AS dm_fm3,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '4'  month,'%Y%m') AND b.cod_instit_financiera = a.ent_alta THEN b.dm ELSE 0 END) AS dm_fm4,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '5'  month,'%Y%m') AND b.cod_instit_financiera = a.ent_alta THEN b.dm ELSE 0 END) AS dm_fm5,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '6'  month,'%Y%m') AND b.cod_instit_financiera = a.ent_alta THEN b.dm ELSE 0 END) AS dm_fm6,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '7'  month,'%Y%m') AND b.cod_instit_financiera = a.ent_alta THEN b.dm ELSE 0 END) AS dm_fm7,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '8'  month,'%Y%m') AND b.cod_instit_financiera = a.ent_alta THEN b.dm ELSE 0 END) AS dm_fm8,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '9'  month,'%Y%m') AND b.cod_instit_financiera = a.ent_alta THEN b.dm ELSE 0 END) AS dm_fm9,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '10' month,'%Y%m') AND b.cod_instit_financiera = a.ent_alta THEN b.dm ELSE 0 END) AS dm_fm10,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '11' month,'%Y%m') AND b.cod_instit_financiera = a.ent_alta THEN b.dm ELSE 0 END) AS dm_fm11,
        max(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m') AND b.cod_instit_financiera = a.ent_alta THEN b.dm ELSE 0 END) AS dm_fm12,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '6' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.dm ELSE null END) AS dias_atraso_6m,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '9' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.dm ELSE null END) AS dias_atraso_9m,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.dm ELSE null END) AS dias_atraso_12m,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '6' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.flag_jud ELSE null END) AS jud_06um,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '9' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.flag_jud ELSE null END) AS jud_09um,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.flag_jud ELSE null END) AS jud_12um,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '6' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.flag_cast ELSE null END) AS cast_06um,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '9' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.flag_cast ELSE null END) AS cast_09um,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.flag_cast ELSE null END) AS cast_12um,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '6' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.flag_ref_ree ELSE null END) AS ree_06um,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '9' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.flag_ref_ree ELSE null END) AS ree_09um,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.flag_ref_ree ELSE null END) AS ree_12um,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '6' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.flag_ref ELSE null END) AS ref_06um,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '9' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.flag_ref ELSE null END) AS ref_09um,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.flag_ref ELSE null END) AS ref_12um,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '6' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.flag_ven ELSE null END) AS ven_06um,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '9' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.flag_ven ELSE null END) AS ven_09um,
        max(CASE WHEN b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') + interval '1' month,'%Y%m')
                                   AND date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m')
                  AND b.cod_instit_financiera = a.ent_alta THEN b.flag_ven ELSE null END) AS ven_12um,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '1'  month,'%Y%m') THEN b.saldo_total ELSE null END) AS sld_m1,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '2'  month,'%Y%m') THEN b.saldo_total ELSE null END) AS sld_m2,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '3'  month,'%Y%m') THEN b.saldo_total ELSE null END) AS sld_m3,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '4'  month,'%Y%m') THEN b.saldo_total ELSE null END) AS sld_m4,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '5'  month,'%Y%m') THEN b.saldo_total ELSE null END) AS sld_m5,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '6'  month,'%Y%m') THEN b.saldo_total ELSE null END) AS sld_m6,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '7'  month,'%Y%m') THEN b.saldo_total ELSE null END) AS sld_m7,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '8'  month,'%Y%m') THEN b.saldo_total ELSE null END) AS sld_m8,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '9'  month,'%Y%m') THEN b.saldo_total ELSE null END) AS sld_m9,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '10' month,'%Y%m') THEN b.saldo_total ELSE null END) AS sld_m10,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '11' month,'%Y%m') THEN b.saldo_total ELSE null END) AS sld_m11,
        sum(CASE WHEN b.codmes = date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m') THEN b.saldo_total ELSE null END) AS sld_m12
    FROM uni a
    LEFT JOIN data_rcc b
        ON a.tip_doc = b.tip_doc
       AND a.key_value = b.key_value
       AND b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') - interval '2' month,'%Y%m')
                        AND date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m')
    GROUP BY a.codmes, a.tip_doc, a.key_value, a.ent_alta, a.cod_instit_financiera, a.nombre_instit_financiera
)
SELECT
    a.*,
    (CASE WHEN sld_m1 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m2 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m3 IS NULL THEN 1 ELSE 0 END) +
    (CASE WHEN sld_m4 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m5 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m6 IS NULL THEN 1 ELSE 0 END) AS nro_miss06,
    (CASE WHEN sld_m1 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m2 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m3 IS NULL THEN 1 ELSE 0 END) +
    (CASE WHEN sld_m4 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m5 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m6 IS NULL THEN 1 ELSE 0 END) +
    (CASE WHEN sld_m7 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m8 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m9 IS NULL THEN 1 ELSE 0 END) AS nro_miss09,
    (CASE WHEN sld_m1 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m2 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m3 IS NULL THEN 1 ELSE 0 END) +
    (CASE WHEN sld_m4 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m5 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m6 IS NULL THEN 1 ELSE 0 END) +
    (CASE WHEN sld_m7 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m8 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m9 IS NULL THEN 1 ELSE 0 END) +
    (CASE WHEN sld_m10 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m11 IS NULL THEN 1 ELSE 0 END) + (CASE WHEN sld_m12 IS NULL THEN 1 ELSE 0 END) AS nro_miss12,
    CASE WHEN saldo_gar_p > 2 THEN '01.1 Garantia Preferida'
         WHEN saldo_gar_np > 2 THEN '01. Garantia NoPreferida'
         ELSE '02. Sin Garantia' END AS flg_garantia,
    CASE WHEN saldo_vig_m0 <= sld_reactiva THEN 1 ELSE 0 END AS flg_solo_reactiva,
    CASE WHEN sld_reactiva > 0 THEN 1 ELSE 0 END AS flg_reactiva,
    CASE WHEN sld_cons_m0 > 0 THEN 1 ELSE 0 END AS flag_cons
FROM info_consolid a
WHERE saldo_vig_m0 > 0
