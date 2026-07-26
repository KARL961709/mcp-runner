-- 20_target_filtros.sql | target + filtros + score | ventana 202206-202506 -> disc_model_owner.ds_adm_bpe_bankbn_mad
-- Origen: Recibidos/enviado_2/02.MaduracionV9_prod_desfase.sql (mono-mes, placeholders @@@@@@ / ssssss / &&&&&&)
--
--  1. UN SOLO STATEMENT (CTAS). Athena no soporta CREATE OR REPLACE: la tabla destino NO debe existir.
--  2. A12 ventana codmes 202206..202506. Placeholders resueltos:
--     @@@@@@ (m0) -> 202206..202506 | ssssss (m0+12) -> 202606 | &&&&&& (m0-12) -> 202106
--     RCC futuro/origen (rcc_fwd): 202204..202606, extendido a m0-2 por A7. RCC pasado (rcc_bwd): 202106..202506.
--  3. A2.2 TARGET POR ENTIDAD DE ALTA. data_rcc pasa a grano (codmes, tip_doc, key_value, cod_instit_financiera).
--     Las ventanas FUTURAS (dm_fm1..dm_fm12, dias_atraso_*, jud/cast/ref/ree/ven_*um) se filtran a ent_alta.
--     Los agregados de ORIGEN (m0 y m2) siguen siendo SISTEMA: miden si el cliente ya venia malo en cualquier entidad.
--     Sumar/maximizar sobre el grano con entidad reproduce exacto el agregado sin entidad: sum(sum)=sum, max(max)=max.
--  4. A4 desfase score: a.codmes = p_codmes + 1. LEFT JOIN (el original era INNER): 40_cal define flg_clean=98
--     para pd_raw NULL, lo que exige que las altas sin score sobrevivan. A3: el denominador son TODAS las altas.
--  5. A7 rezago por fuente. Columnas paralelas *_m2 calculadas a m0-2 para los 8 filtros CASO2 (todos RCC).
--     No se borran las de m0: quedan ambas para poder medir el delta del relagueo (analisis_N2 seccion 5).
--     RENIEC (fec_nacimiento) y SUNAT/especiales no se relaguean: A7 los deja sin rezago o los manda a CASO1.
--  6. Q1 target_12m: el original copiaba las ventanas de 6m. Corregido a dias_atraso_12m y *_12um.
--  7. Q5 ventanas 12um -> [m0-12, m0-2]. Se emiten como *_v2 (saldo_novig_neg_12um_v2, sld_castigado_12um_rl_v2),
--     que es lo que consume 40_cal. Las originales [m0-11, m0] se conservan porque flag_bpe_parcial las usa.
--  8. MONTH-AWARE. El original une por tip_doc/key_value porque el seed es un unico mes. Con 37 meses:
--     8.1 los CTE con CASE por ventana relativa a a.codmes ya son month-aware (rcc_titular, rcc_rl, info_consolid).
--     8.2 los semi-joins de universo pasan a SELECT DISTINCT tip_doc,key_value: mismo resultado, sin fan 37x.
--     8.3 filtro_sunat, cruce_titular, base_cny y especial_cny ya particionan por codmes en el RANK.
--  9. flag_bpe_parcial se mantiene TAL CUAL el vigente (usa las ventanas m0 y [m0-11,m0]): 40_cal solo lee de el
--     las ramas PNSN (CASO3) y SUNAT estado/giro/ubigeo (CASO1). Los CASO2 los lee de las columnas *_m2 directas.
-- 10. Q2 se mantiene: 23. Ubigeo Restringido no excluye en flag_malo_*, es CASO1 igual.
-- 11. Se agrega b.probabilidad (pd_raw) ademas de b.puntuacion, y se exponen fec_nacimiento,
--     fec_nacimiento_rl_min/max, tipo_personeria, cod_instit_financiera y nombre_instit_financiera: los pide 40_cal.
-- 12. COLISION DE NOMBRE: el m-2 de dias de atraso al origen se emite como dm_org_m2, NO como dm_fm2.
--     dm_fm2 ya existe en el original y significa m0+2 (futuro). 40_cal linea 66 lee d.dm_fm2 -> debe leer d.dm_org_m2.
-- 13. Control: falla_sin_score, falla_score_dup, falla_pd_rango, falla_sin_entidad_alta, falla_madurez_12m,
--     falla_sin_rcc_futuro, falla_target_nulo.
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_mad AS
WITH uni AS (
    SELECT
        codmes,
        tip_doc,
        key_value,
        cod_instit_financiera AS ent_alta,
        cod_instit_financiera,
        nombre_instit_financiera
    FROM disc_model_owner.ds_adm_bpe_bankbn_po
    WHERE codmes BETWEEN '202206' AND '202506'
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
    FROM e_perm_aws.t_fact_report_rcc_rsk a
    INNER JOIN uni_key b
        ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value
    WHERE a.p_codmes BETWEEN '202204' AND '202606'
      AND a.codmes   BETWEEN '202204' AND '202606'
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
),
morigbk_saldo_hist AS (
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
),
uni_mad AS (
    SELECT DISTINCT codmes, tip_doc, key_value FROM morigbk_saldo_hist
),
uni_mad_key AS (
    SELECT DISTINCT tip_doc, key_value FROM morigbk_saldo_hist
),
uni_conyuge AS (
    SELECT
        a.codmes,
        a.key_value,
        a.tip_doc,
        b.tipdoc_conyugue,
        b.coddoc_conyugue,
        b.fec_nacimiento AS fec_nacimiento
    FROM (SELECT codmes, tip_doc, key_value FROM uni_mad WHERE tip_doc <> '2') a
    LEFT JOIN e_perm_aws.t_mst_reniec_rsk b
        ON a.key_value = b.key_value AND a.tip_doc = b.tip_doc
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
    WHERE a.p_codmes BETWEEN '202106' AND '202506'
      AND a.codmes   BETWEEN '202106' AND '202506'
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
),
rcc_titular AS (
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
    GROUP BY a.codmes, a.tip_doc, a.key_value
),
uni_rl AS (
    SELECT
        b.codmes,
        b.key_value,
        b.tip_doc,
        a.key_value AS nrodoc_rl,
        a.tip_doc   AS tipdoc_rl
    FROM e_perm_aws.t_mst_rep_legal_sunat_rsk a
    INNER JOIN uni_mad b
        ON a.ruc_value = b.key_value
       AND cast(date_format(date_parse(cast(a.fec_vigencia AS varchar),'%Y-%m-%d'), '%Y%m') AS int) <= cast(b.codmes AS int)
    GROUP BY b.codmes, b.key_value, b.tip_doc, a.key_value, a.tip_doc
),
nacimiento_rl AS (
    SELECT
        a.codmes,
        a.key_value,
        a.tip_doc,
        min(c.fec_nacimiento) AS fec_nacimiento_rl_min,
        max(c.fec_nacimiento) AS fec_nacimiento_rl_max
    FROM uni_rl a
    LEFT JOIN e_perm_aws.t_mst_reniec_rsk c
        ON a.nrodoc_rl = c.key_value AND a.tipdoc_rl = c.tip_doc
    GROUP BY 1,2,3
),
uni_rl_key AS (
    SELECT DISTINCT nrodoc_rl, tipdoc_rl FROM uni_rl
),
fea_rcc_rl AS (
    SELECT
        b.codmes,
        a.nrodoc_rl,
        a.tipdoc_rl,
        sum(CASE WHEN (substr(b.cod_cuenta_rcc,1,2)='81' AND substr(b.cod_cuenta_rcc,4,3) IN ('302','925')) THEN b.saldo ELSE null END) AS sld_castigado
    FROM uni_rl_key a
    INNER JOIN (
        SELECT a.codmes, a.tip_doc, a.key_value, a.cod_cuenta_rcc, a.saldo
        FROM e_perm_aws.t_fact_report_rcc_rsk a
        INNER JOIN (SELECT DISTINCT nrodoc_rl, tipdoc_rl FROM uni_rl) k
            ON a.key_value = k.nrodoc_rl AND a.tip_doc = k.tipdoc_rl
        WHERE a.p_codmes BETWEEN '202106' AND '202506'
          AND a.codmes   BETWEEN '202106' AND '202506'
    ) b
        ON a.nrodoc_rl = b.key_value AND a.tipdoc_rl = b.tip_doc
    GROUP BY b.codmes, a.nrodoc_rl, a.tipdoc_rl
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
    FROM uni_rl a
    LEFT JOIN fea_rcc_rl b
        ON a.nrodoc_rl = b.nrodoc_rl AND a.tipdoc_rl = b.tipdoc_rl
    GROUP BY a.codmes, a.nrodoc_rl, a.tipdoc_rl
),
rcc_rl_titular AS (
    SELECT
        a.codmes,
        a.tip_doc,
        a.key_value,
        sum(b.sld_castigado_12um_rl)    AS sld_castigado_12um_rl,
        sum(b.sld_castigado_12um_rl_v2) AS sld_castigado_12um_rl_v2
    FROM uni_rl a
    LEFT JOIN rcc_rl b
        ON a.codmes = b.codmes AND a.tipdoc_rl = b.tipdoc_rl AND a.nrodoc_rl = b.nrodoc_rl
    GROUP BY a.codmes, a.tip_doc, a.key_value
),
filtro_sunat AS (
    SELECT DISTINCT a.*
    FROM (
        SELECT a.*,
               RANK() OVER (PARTITION BY codmes, tip_doc, key_value
                            ORDER BY codmes, tip_doc, key_value, cl_estado_num ASC, fecalta2 DESC) AS num
        FROM (
            SELECT DISTINCT y.*,
                (CASE WHEN y.tpoemp IN ('01') THEN 'PPNNSN'
                      WHEN y.tpoemp IN ('02') THEN 'PPNNCN'
                      WHEN y.tpoemp IN ('07') THEN 'EIRL'
                      WHEN y.tpoemp IN ('08') THEN 'SOCIEDAD CIVIL'
                      WHEN y.tpoemp IN ('09') THEN 'SOCIEDAD IRREGULAR'
                      WHEN y.tpoemp IN ('11') THEN 'ASOCIACION'
                      WHEN y.tpoemp IN ('19') THEN 'CENTROS EDUCATIVO'
                      WHEN y.tpoemp IN ('26') THEN 'SA'
                      WHEN y.tpoemp IN ('28') THEN 'SCRL'
                      WHEN y.tpoemp IN ('39') THEN 'SAC'
                      WHEN y.tpoemp IN ('43') THEN 'SMRL' ELSE 'OTROS' END) AS cl_tpoemp,
                (CASE WHEN y.estado IN ('00')           THEN 'ACTIVO'
                      WHEN y.estado IN ('01','02')      THEN 'BAJA PROV.'
                      WHEN y.estado IN ('03')           THEN 'SUSPENSION TEMP.'
                      WHEN y.estado IN ('04')           THEN 'ANUL.PROVI.-ACTO ILICITO'
                      WHEN y.estado IN ('10','11','12') THEN 'CASERIO'
                      WHEN y.estado IN ('21')           THEN 'OTROS OBLIG.'
                      WHEN y.estado IN ('22')           THEN 'INHABILITADO'
                      WHEN y.estado IN ('30','31')      THEN 'ANULACION'
                      WHEN y.estado IN ('32')           THEN 'PEND. INI. ACTIV.' ELSE 'MISSING' END) AS cl_estado,
                (CASE WHEN y.estado IN ('00') THEN 1 ELSE 0 END) AS cl_estado_num
            FROM (
                SELECT DISTINCT x.codmes, x.tip_doc, x.key_value,
                    (CASE WHEN (CAST(SUBSTR(y.fecalta2,1,6) AS INTEGER) > cast(x.codmes AS integer)) THEN 'SIN_DATO' ELSE y.tipcontribuyente     END) AS tpoemp,
                    (CASE WHEN (CAST(SUBSTR(y.fecalta2,1,6) AS INTEGER) > cast(x.codmes AS integer)) THEN 'SIN_DATO' ELSE y.estadocontribuyente  END) AS estado,
                    (CASE WHEN (CAST(SUBSTR(y.fecalta2,1,6) AS INTEGER) > cast(x.codmes AS integer)) THEN 'SIN_DATO' ELSE y.ubigeo               END) AS ubigeo,
                    (CASE WHEN (CAST(SUBSTR(y.fecalta2,1,6) AS INTEGER) > cast(x.codmes AS integer)) THEN ''         ELSE y.fecalta2             END) AS fecalta2,
                    (CASE WHEN (CAST(SUBSTR(y.fecalta2,1,6) AS INTEGER) > cast(x.codmes AS integer)) THEN 'SIN_DATO' ELSE y.ciiu                 END) AS ciiu
                FROM uni_mad x
                LEFT JOIN (
                    SELECT x.*,
                        (CASE WHEN x.flg_ruc = 10 THEN '1'
                              WHEN x.flg_ruc = 15 THEN '1'
                              WHEN x.flg_ruc = 17 THEN '1' ELSE '2' END) AS tipdoc,
                        (CASE WHEN (x.flg_ruc = 10 OR x.flg_ruc = 15 OR x.flg_ruc = 17) THEN y.key_value ELSE x.ruc_value END) AS nrodoc
                    FROM (SELECT a.*, cast(extract(year FROM a.fecalta)*10000 + extract(month FROM a.fecalta)*100 + extract(day FROM a.fecalta) AS varchar(8)) AS fecalta2
                          FROM e_perm_aws.t_mst_princ_sunat_rsk a) x
                    LEFT JOIN (
                        SELECT *,
                            RANK() OVER (PARTITION BY tip_doc, key_value ORDER BY fecproceso, fecinicio, estadoregistro, ruc_value DESC) AS num
                        FROM e_perm_aws.t_mst_sec_sunat_rsk) y
                        ON (x.ruc_value = y.ruc_value) AND y.num = 1
                    WHERE x.fecalta2 <> '') y
                ON (x.tip_doc = y.tipdoc AND x.key_value = y.nrodoc)
            ) y
        ) a
    ) a
    WHERE a.num = 1
),
filtro_sunat2 AS (
    SELECT a.codmes, a.tip_doc, a.key_value,
           b.tpoemp, b.estado, b.fecalta2, b.ciiu, b.ubigeo, b.cl_tpoemp, b.cl_estado, b.cl_estado_num
    FROM uni_mad a
    LEFT JOIN filtro_sunat b
        ON a.codmes = b.codmes AND a.tip_doc = b.tip_doc AND a.key_value = b.key_value
),
filtros_bpe AS (
    SELECT DISTINCT a.*,
        CASE WHEN tpoemp = '01' THEN 'PPNN_SN' WHEN tpoemp = '02' THEN 'PPNN_CN' ELSE 'PPJJ' END AS tipo_personeria,
        CASE WHEN cl_estado = 'ACTIVO' AND tpoemp <> '01' AND ubigeo_restringido <> 1 AND giro_restringido <> 1
              AND (trim(ubigeo) NOT IN ('SIN_DATO','')) THEN 1 ELSE 0 END AS flag_bpe_v1,
        CASE WHEN cl_estado = 'ACTIVO' AND ubigeo_restringido <> 1 AND giro_restringido <> 1
              AND (trim(ubigeo) NOT IN ('SIN_DATO','')) THEN 1 ELSE 0 END AS flag_bpe_v2
    FROM (
        SELECT a.*,
            CASE WHEN c.flag_aceptanuevos = 'Restringido' THEN 1
                 WHEN c.flag_aceptanuevos = 'Atendido'    THEN 0 ELSE -1 END AS giro_restringido,
            CASE WHEN d.flag_zonabpe = 'Atendido'    THEN 0
                 WHEN d.flag_zonabpe = 'Restringido' THEN 1 ELSE -1 END AS ubigeo_restringido
        FROM filtro_sunat2 a
        LEFT JOIN (SELECT codigoacteconomica, max(flag_aceptanuevos) AS flag_aceptanuevos FROM e_perm_aws.t_mst_bpe_giros_restringidos GROUP BY 1) c
            ON a.ciiu = c.codigoacteconomica
        LEFT JOIN (SELECT cod_ubigeo, max(flag_zonabpe) AS flag_zonabpe FROM e_perm_aws.t_mst_bpe_ubigeos_restringidos GROUP BY 1) d
            ON a.ubigeo = d.cod_ubigeo
    ) a
),
flag_bpe AS (
    SELECT
        a.*,
        b.sld_castigado_12um_rl,
        b.sld_castigado_12um_rl_v2,
        d.fec_nacimiento,
        f.fec_nacimiento_rl_min,
        f.fec_nacimiento_rl_max,
        h.saldo_novig_neg_12um,
        h.saldo_novig_neg_12um_v2,
        h.saldo_novig_neg_1um,
        h.saldo_novig_neg_1um_m2,
        h.saldo_nonormal_1um,
        h.saldo_nonormal_1um_m2,
        j.tpoemp,
        j.estado,
        j.fecalta2,
        j.ciiu,
        j.ubigeo,
        j.cl_tpoemp,
        j.cl_estado,
        j.tipo_personeria,
        j.giro_restringido,
        j.ubigeo_restringido,
        j.flag_bpe_v1,
        j.flag_bpe_v2,
        CASE WHEN h.saldo_novig_neg_1um > 0 THEN '01. Titular con Saldo Comercial No Vigente RCC (Ultimo mes)'
             WHEN h.saldo_novig_neg_12um > 0 THEN '02. Titular con Saldo Comercial No Vigente RCC (Ultimos 12 meses)'
             WHEN h.saldo_nonormal_1um > 0 THEN '03. Titular con Calificacion SBS diferente a 100% Normal'
             WHEN b.sld_castigado_12um_rl > 0 THEN '09. RRLL con Saldo RCC en Castigo (Ultimos 12 meses)'
             WHEN (COALESCE(CAST(SUBSTRING(a.codmes,1,4) AS INT) - cast(EXTRACT(YEAR FROM d.fec_nacimiento) AS int), 30) <= 25)
               OR (COALESCE(CAST(SUBSTRING(a.codmes,1,4) AS INT) - cast(EXTRACT(YEAR FROM d.fec_nacimiento) AS int), 30) >= 75) THEN '17. Titular >= 75 o < 25 anos'
             WHEN (COALESCE(CAST(SUBSTRING(a.codmes,1,4) AS INT) - cast(EXTRACT(YEAR FROM f.fec_nacimiento_rl_max) AS int), 30) <= 25)
               OR (COALESCE(CAST(SUBSTRING(a.codmes,1,4) AS INT) - cast(EXTRACT(YEAR FROM f.fec_nacimiento_rl_min) AS int), 30) >= 75) THEN '18. RRLL >= 75 o < 25 anos'
             WHEN j.tipo_personeria = 'PPNN_SN' THEN '19. PNSN'
             WHEN j.estado NOT IN ('00','03') THEN '20. Estado Diferente A'
             WHEN j.giro_restringido = 1 THEN '22. Giro Restringido'
             WHEN j.ubigeo_restringido = 1 THEN '23. Ubigeo Restringido'
             ELSE '99. Sin Caida' END AS flag_bpe_parcial
    FROM morigbk_saldo_hist a
    LEFT JOIN rcc_rl_titular b ON a.key_value = b.key_value AND a.tip_doc = b.tip_doc AND a.codmes = b.codmes
    LEFT JOIN uni_conyuge    d ON a.key_value = d.key_value AND a.tip_doc = d.tip_doc AND a.codmes = d.codmes
    LEFT JOIN nacimiento_rl  f ON a.key_value = f.key_value AND a.tip_doc = f.tip_doc AND a.codmes = f.codmes
    LEFT JOIN rcc_titular    h ON a.key_value = h.key_value AND a.tip_doc = h.tip_doc AND a.codmes = h.codmes
    LEFT JOIN filtros_bpe    j ON a.key_value = j.key_value AND a.tip_doc = j.tip_doc AND a.codmes = j.codmes
),
especiales AS (
    SELECT
        a.cliente_id,
        a.fecha_dt,
        CASE WHEN a.fecha_dt = '' THEN null ELSE substring(a.fecha_dt, 1, 10) END AS fechaingreso,
        CASE WHEN a.fecha_habilita_dt = '' THEN null ELSE substring(a.fecha_habilita_dt, 1, 10) END AS fechahabilita,
        b.cod_tipo_doc_val AS tip_doc,
        b.num_doc_val      AS key_value,
        CASE a.cod_tipo_val
            WHEN '1' THEN 'Negativo'
            WHEN '2' THEN 'Sobreendeudamiento'
            WHEN '3' THEN 'Vigilancia Especial'
            ELSE 'Error'
        END AS tipoingreso
    FROM (SELECT cliente_id, fecha_dt, fecha_habilita_dt, cod_tipo_val FROM e_perm_aws.t_rel_vpc_myp_clientenegativo GROUP BY 1,2,3,4) a
    JOIN (SELECT cliente_id, cod_tipo_doc_val, num_doc_val FROM e_perm_aws.t_mst_vpc_myp_cliente_actual GROUP BY 1,2,3) b
        ON a.cliente_id = b.cliente_id
),
especiales_win AS (
    SELECT *,
        DATE_FORMAT(DATE_TRUNC('MONTH', COALESCE(CAST(fechahabilita AS DATE), CURRENT_DATE)), '%Y%m') AS considerar_hasta,
        DATE_FORMAT(DATE_TRUNC('MONTH', CAST(fechaingreso AS DATE)), '%Y%m') AS codmesfechaingreso
    FROM especiales
    WHERE tipoingreso IN ('Vigilancia Especial', 'Sobreendeudamiento', 'Negativo')
),
cruce_titular AS (
    SELECT
        a.*,
        CASE WHEN b.tip_doc IS NOT NULL AND b.key_value IS NOT NULL THEN 'Cruce' ELSE 'No Cruce' END AS flagcruce,
        RANK() OVER (PARTITION BY a.codmes, a.tip_doc, a.key_value ORDER BY a.codmes, a.tip_doc, a.key_value, b.fecha_dt DESC) AS num
    FROM flag_bpe a
    LEFT JOIN especiales_win b
        ON a.tip_doc = b.tip_doc
       AND a.key_value = b.key_value
       AND (a.codmes < b.considerar_hasta AND a.codmes >= b.codmesfechaingreso)
),
base_cny AS (
    SELECT
        a.codmes,
        a.key_value,
        a.tip_doc,
        b.tipdoc_conyugue,
        b.coddoc_conyugue,
        b.fec_inscripcion,
        RANK() OVER (PARTITION BY a.codmes, b.tipdoc_conyugue, b.coddoc_conyugue
                     ORDER BY a.codmes, b.tipdoc_conyugue, b.coddoc_conyugue, b.fec_inscripcion DESC) AS num
    FROM (SELECT * FROM cruce_titular WHERE tip_doc <> '2' AND num = 1) a
    INNER JOIN e_perm_aws.t_mst_reniec_rsk b
        ON a.key_value = b.key_value
       AND CAST(CAST(a.tip_doc AS INT) AS VARCHAR) = b.tip_doc
    WHERE TRIM(b.tipdoc_conyugue) <> ''
      AND TRIM(b.coddoc_conyugue) <> ''
),
especial_cny AS (
    SELECT
        a.codmes,
        a.tipdoc_conyugue,
        a.coddoc_conyugue,
        a.key_value,
        a.tip_doc,
        CASE WHEN b.tip_doc IS NOT NULL AND b.key_value IS NOT NULL THEN 'Cruce' ELSE 'No Cruce' END AS flagcruce_cny,
        RANK() OVER (PARTITION BY a.codmes, a.tip_doc, a.key_value ORDER BY a.codmes, a.tip_doc, a.key_value, b.fecha_dt DESC) AS num
    FROM (SELECT * FROM base_cny WHERE num = 1) a
    LEFT JOIN especiales_win b
        ON a.tipdoc_conyugue = b.tip_doc
       AND a.coddoc_conyugue = b.key_value
       AND (a.codmes < b.considerar_hasta AND a.codmes >= b.codmesfechaingreso)
),
base_flag_cny AS (
    SELECT
        a.*,
        b.flagcruce_cny
    FROM (SELECT * FROM cruce_titular WHERE num = 1) a
    LEFT JOIN (SELECT * FROM especial_cny WHERE num = 1) b
        ON a.codmes = b.codmes AND a.tip_doc = b.tip_doc AND a.key_value = b.key_value
),
score AS (
    SELECT *
    FROM e_perm_aws.scr_admbankbpe_rsk
    WHERE p_codmes BETWEEN '202205' AND '202505'
)
SELECT
  a.codmes,
  a.codmes AS p_codmes,
  a.tip_doc,
  a.key_value,
  a.cod_instit_financiera,
  a.nombre_instit_financiera,
  a.ent_alta,

  b.puntuacion,
  b.probabilidad,
  b.woe_beta_sldoppcomer,
  b.woe_prm_decresldo12m,
  b.woe_nro_decresldo12m,
  b.woe_beta_nroenti,
  b.woe_max_nrocredsldo06m,
  b.woe_prm_porcsldoimpa12m,
  b.woe_peor_clasicony09m,
  b.woe_prm_decresldopp12m,
  b.woe_prm_usotcfueraibk12m,
  b.woe_prm_decresldotc12m,
  b.woe_beta_sldopp12m,
  b.woe_max_dismsldonoprinc12m,
  b.woe_max_nroentinegocny06m,
  b.woe_nro_mesesatrasmay8dias09m,
  b.woe_max_dismsldoretail03m,
  b.woe_beta_sldotc12m,
  b.woe_rat_sldo09msobre12mrl,
  b.woe_max_diasatras09mrl,
  b.woe_nro_dismsaldonormal12mcny,
  b.woe_max_dismsldo12rl,
  b.woe_nro_mesesdismsldoretail12m,
  b.woe_rat_sldonormal3msobre12mrl,
  b.woe_porc_messldogiro06m,
  b.woe_prm_ratdispefect03m,
  b.woe_nro_mesesdicmsldoprinc12m,
  b.woe_prm_valorexpimp12m,
  b.woe_min_sldopasi06m,
  b.woe_cant_entireportsisnoreg,
  b.woe_prm_deudatelco12m,
  b.woe_cant_vehi,
  b.woe_anti_negmeses,
  b.woe_prm_nrotrxcashout06m,
  b.woe_nro_mesescastin06m,
  b.woe_edad,
  b.woe_dpt_grupo_v2,
  b.woe_ciiu_grupo_v2,
  b.rat_promsldnegdecreprin3y6m,
  b.rat_promsldnegdecre03y06m,
  b.woe_avg_porcsald_otrasent12m,

  a.dm_fm1,
  a.dm_fm2,
  a.dm_fm3,
  a.dm_fm4,
  a.dm_fm5,
  a.dm_fm6,
  a.dm_fm7,
  a.dm_fm8,
  a.dm_fm9,
  a.dm_fm10,
  a.dm_fm11,
  a.dm_fm12,

  a.sld_m1,
  a.sld_m2,
  a.sld_m3,
  a.sld_m4,
  a.sld_m5,
  a.sld_m6,
  a.sld_m7,
  a.sld_m8,
  a.sld_m9,
  a.sld_m10,
  a.sld_m11,
  a.sld_m12,
  a.nro_miss06,
  a.nro_miss09,
  a.nro_miss12,

  a.saldo_vig_m0,
  a.sld_cons_m0,
  a.sld_reactiva,
  a.clasificacion_m0,
  a.dm_fm0,
  a.saldo_ref_m0,
  a.saldo_jud_mo,
  a.saldo_cast_mo,
  a.saldo_rest_mo,

  a.saldo_vig_m2,
  a.clasificacion_m2,
  a.dm_org_m2,
  a.saldo_ref_m2,
  a.saldo_jud_m2,
  a.saldo_cast_m2,
  a.saldo_rest_m2,

  a.saldo_novig_neg_1um,
  a.saldo_novig_neg_1um_m2,
  a.saldo_nonormal_1um,
  a.saldo_nonormal_1um_m2,
  a.saldo_novig_neg_12um,
  a.saldo_novig_neg_12um_v2,
  a.sld_castigado_12um_rl,
  a.sld_castigado_12um_rl_v2,

  a.fec_nacimiento,
  a.fec_nacimiento_rl_min,
  a.fec_nacimiento_rl_max,

  a.dias_atraso_6m,
  a.dias_atraso_9m,
  a.dias_atraso_12m,
  a.jud_06um,
  a.jud_09um,
  a.jud_12um,
  a.cast_06um,
  a.cast_09um,
  a.cast_12um,
  a.ref_06um,
  a.ref_09um,
  a.ref_12um,
  a.ree_06um,
  a.ree_09um,
  a.ree_12um,
  a.ven_06um,
  a.ven_09um,
  a.ven_12um,

  CASE WHEN a.dias_atraso_6m  > 90 OR a.jud_06um = 1 OR a.cast_06um = 1 OR a.ref_06um = 1 OR a.ree_06um = 1 THEN 1 ELSE 0 END AS target_06m,
  CASE WHEN a.dias_atraso_9m  > 90 OR a.jud_09um = 1 OR a.cast_09um = 1 OR a.ref_09um = 1 OR a.ree_09um = 1 THEN 1 ELSE 0 END AS target_09m,
  CASE WHEN a.dias_atraso_12m > 90 OR a.jud_12um = 1 OR a.cast_12um = 1 OR a.ref_12um = 1 OR a.ree_12um = 1 THEN 1 ELSE 0 END AS target_12m,

  a.flg_garantia,
  CASE
      WHEN a.flg_reactiva = 0 AND a.flg_solo_reactiva = 0 THEN 'SOLO NEGOCIO'
      WHEN a.flg_reactiva = 1 AND a.flg_solo_reactiva = 0 THEN 'MIXTO'
      WHEN a.flg_reactiva = 1 AND a.flg_solo_reactiva = 1 THEN 'REACTIVA'
      ELSE 'SIN DEUDA'
  END AS segmento_reactiva,
  a.flg_reactiva,
  a.flg_solo_reactiva,
  a.flag_cons,
  a.tipo_personeria,
  a.estado,
  a.ciiu,
  a.ubigeo,
  a.cl_estado,
  a.cl_tpoemp,
  a.giro_restringido,
  a.ubigeo_restringido,
  a.flag_bpe_v1,
  a.flag_bpe_v2,
  a.flag_bpe_parcial,
  a.flagcruce_cny,
  a.flagcruce,

  CASE
      WHEN a.saldo_cast_mo IS NOT NULL THEN 'CASTIGADO_ORIGEN'
      WHEN a.saldo_jud_mo  IS NOT NULL THEN 'JUDICIAL_ORIGEN'
      WHEN a.saldo_rest_mo IS NOT NULL THEN 'REESTRUCTURADO_ORIGEN'
      WHEN a.saldo_ref_m0  IS NOT NULL THEN 'REFINANCIADO_ORIGEN'
      WHEN a.clasificacion_m0 NOT IN ('0') THEN 'CLASIF_NO_NORMAL'
      WHEN a.flag_bpe_parcial NOT IN ('23. Ubigeo Restringido','99. Sin Caida') THEN 'NO_BPE'
      WHEN a.dm_fm0 > 0 THEN 'CON_DIASATRASO_ORIGEN'
      WHEN a.flagcruce = 'Cruce' OR a.flagcruce_cny = 'Cruce' THEN 'ESPECIALES'
      WHEN a.nro_miss06 = 6 THEN 'SIN_INFORMACION'
      WHEN a.nro_miss06 > 3 THEN 'INSUFICIENTE'
      WHEN a.dias_atraso_6m > 90 OR a.jud_06um = 1 OR a.cast_06um = 1 OR a.ref_06um = 1 OR a.ree_06um = 1 THEN 'MALO'
      WHEN a.dias_atraso_6m <= 90 AND a.dias_atraso_6m > 30 THEN 'INDETERMINADO'
      ELSE 'BUENO'
  END AS flag_malo_06m,
  CASE
      WHEN a.saldo_cast_mo IS NOT NULL THEN 'CASTIGADO_ORIGEN'
      WHEN a.saldo_jud_mo  IS NOT NULL THEN 'JUDICIAL_ORIGEN'
      WHEN a.saldo_rest_mo IS NOT NULL THEN 'REESTRUCTURADO_ORIGEN'
      WHEN a.saldo_ref_m0  IS NOT NULL THEN 'REFINANCIADO_ORIGEN'
      WHEN a.clasificacion_m0 NOT IN ('0') THEN 'CLASIF_NO_NORMAL'
      WHEN a.flag_bpe_parcial NOT IN ('23. Ubigeo Restringido','99. Sin Caida') THEN 'NO_BPE'
      WHEN a.dm_fm0 > 0 THEN 'CON_DIASATRASO_ORIGEN'
      WHEN a.flagcruce = 'Cruce' OR a.flagcruce_cny = 'Cruce' THEN 'ESPECIALES'
      WHEN a.nro_miss09 = 9 THEN 'SIN_INFORMACION'
      WHEN a.nro_miss09 > 4 THEN 'INSUFICIENTE'
      WHEN a.dias_atraso_9m > 90 OR a.jud_09um = 1 OR a.cast_09um = 1 OR a.ref_09um = 1 OR a.ree_09um = 1 THEN 'MALO'
      WHEN a.dias_atraso_9m <= 90 AND a.dias_atraso_9m > 30 THEN 'INDETERMINADO'
      ELSE 'BUENO'
  END AS flag_malo_09m,
  CASE
      WHEN a.saldo_cast_mo IS NOT NULL THEN 'CASTIGADO_ORIGEN'
      WHEN a.saldo_jud_mo  IS NOT NULL THEN 'JUDICIAL_ORIGEN'
      WHEN a.saldo_rest_mo IS NOT NULL THEN 'REESTRUCTURADO_ORIGEN'
      WHEN a.saldo_ref_m0  IS NOT NULL THEN 'REFINANCIADO_ORIGEN'
      WHEN a.clasificacion_m0 NOT IN ('0') THEN 'CLASIF_NO_NORMAL'
      WHEN a.flag_bpe_parcial NOT IN ('23. Ubigeo Restringido','99. Sin Caida') THEN 'NO_BPE'
      WHEN a.dm_fm0 > 0 THEN 'CON_DIASATRASO_ORIGEN'
      WHEN a.flagcruce = 'Cruce' OR a.flagcruce_cny = 'Cruce' THEN 'ESPECIALES'
      WHEN a.nro_miss12 = 12 THEN 'SIN_INFORMACION'
      WHEN a.nro_miss12 > 6 THEN 'INSUFICIENTE'
      WHEN a.dias_atraso_12m > 90 OR a.jud_12um = 1 OR a.cast_12um = 1 OR a.ref_12um = 1 OR a.ree_12um = 1 THEN 'MALO'
      WHEN a.dias_atraso_12m <= 90 AND a.dias_atraso_12m > 30 THEN 'INDETERMINADO'
      ELSE 'BUENO'
  END AS flag_malo_12m,

  CASE WHEN b.probabilidad IS NULL THEN 1 ELSE 0 END AS falla_sin_score,
  CASE WHEN count(1) OVER (PARTITION BY a.codmes, a.tip_doc, a.key_value) > 1 THEN 1 ELSE 0 END AS falla_score_dup,
  CASE WHEN b.probabilidad IS NOT NULL
        AND (TRY_CAST(b.probabilidad AS double) IS NULL
             OR TRY_CAST(b.probabilidad AS double) < 0
             OR TRY_CAST(b.probabilidad AS double) > 1) THEN 1 ELSE 0 END AS falla_pd_rango,
  CASE WHEN a.ent_alta IS NULL THEN 1 ELSE 0 END AS falla_sin_entidad_alta,
  CASE WHEN date_format(date_parse(a.codmes,'%Y%m') + interval '12' month,'%Y%m') > '202606' THEN 1 ELSE 0 END AS falla_madurez_12m,
  CASE WHEN a.nro_miss12 = 12 THEN 1 ELSE 0 END AS falla_sin_rcc_futuro,
  CASE WHEN a.dias_atraso_12m IS NULL AND a.jud_12um IS NULL AND a.cast_12um IS NULL
        AND a.ref_12um IS NULL AND a.ree_12um IS NULL THEN 1 ELSE 0 END AS falla_target_nulo
FROM base_flag_cny a
LEFT JOIN score b
    ON a.tip_doc = b.tip_doc
   AND a.key_value = b.key_value
   AND a.codmes = date_format(date_parse(b.p_codmes,'%Y%m') + interval '1' month,'%Y%m')
