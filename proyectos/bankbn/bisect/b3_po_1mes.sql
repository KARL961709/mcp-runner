-- b3 LOGICA COMPLETA de 10_po, ventana 1 mes (202405), read-only
SELECT COUNT(*) AS n_filas, COUNT(DISTINCT concat(tip_doc,key_value)) AS clientes FROM (
WITH morigbk_tag AS (
    SELECT codmes, tip_doc, key_value, condicion, tipo_credito, cod_cuenta_rcc, cod_instit_financiera,
           cod_clasificacion_deudor, saldo,
        CASE
            WHEN substr(a.cod_cuenta_rcc,1,2)='14' AND substr(a.cod_cuenta_rcc,4,1) IN ('1','3','4','5','6') THEN
                CASE WHEN cast(tipo_credito AS int) BETWEEN 8 AND 10 THEN
                        CASE
                            WHEN (cast(tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='05' THEN 'DESCUENTOS'
                            WHEN (cast(tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='10' THEN 'FACTORING'
                            WHEN (cast(tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='04' THEN 'SOBREGIRO'
                            WHEN (cast(tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='01' THEN 'AVANCE CC'
                            ELSE 'RESTO DD NEGOCIO'
                        END
                    ELSE 'RESTO DD'
                END
            WHEN substr(a.cod_cuenta_rcc,1,2)='72' AND substr(a.cod_cuenta_rcc,4,1)='5' THEN
                CASE WHEN cast(tipo_credito AS int) BETWEEN 8 AND 10 THEN
                        CASE
                            WHEN (cast(tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,5,2)='02' THEN 'LC DESCUENTO'
                            WHEN (cast(tipo_credito AS int) BETWEEN 8 AND 10) AND substr(a.cod_cuenta_rcc,5,2) IN ('03','06','08','09') THEN 'LC NO UTILIZADA'
                            ELSE 'RESTO LC NEGOCIO'
                        END
                    ELSE 'RESTO LC'
                END
        ELSE 'OTROS' END AS tag,
        CASE WHEN cod_instit_financiera IN ('00469','00470','00472','00477','00478','00497','00498','00499','00500','00508',
                    '00509','00510','00512','00513','00514','00516','00517','00518','00519','00580','00581','00582','00583',
                    '00587','00588','00589','00592','00593','00594','00596','00598','00599','00600') THEN 1 ELSE 0 END AS ent_honrada
    FROM (
        SELECT codmes, tip_doc, key_value, condicion, tipo_credito, cod_cuenta_rcc, cod_instit_financiera,
               cod_clasificacion_deudor, saldo
        FROM e_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes BETWEEN '202403' AND '202407'
          AND codmes   BETWEEN '202206' AND '202506'
    ) a
),
morigbk_rcc AS (
    SELECT DISTINCT a.codmes, a.tip_doc, a.key_value, a.condicion, a.tipo_credito, a.cod_cuenta_rcc,
           a.cod_instit_financiera, a.cod_clasificacion_deudor, a.saldo,
        CASE
            WHEN substr(a.cod_cuenta_rcc,1,2)='14' AND substr(a.cod_cuenta_rcc,4,1) IN ('1','3','4','5','6') THEN
                CASE
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='05' THEN 'DESCUENTOS'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='10' THEN 'FACTORING'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='04' THEN 'SOBREGIRO'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='01' THEN 'AVANCE CC'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,4,1)='4' THEN 'REFINANCIADOS'
                    ELSE 'RESTO DD'
                END
            WHEN substr(a.cod_cuenta_rcc,1,2)='72' AND substr(a.cod_cuenta_rcc,4,1)='5' THEN
                CASE
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,5,2)='02' THEN 'LC DESCUENTO'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,5,2) IN ('03','06','08','09') THEN 'LC NO UTILIZADA'
                    ELSE 'RESTO LC'
                END
        ELSE 'OTROS' END AS tag,
        CASE WHEN a.cod_instit_financiera IN ('00469','00470','00472','00477','00478','00497','00498','00499','00500','00508',
                    '00509','00510','00512','00513','00514','00516','00517','00518','00519','00580','00581','00582','00583',
                    '00587','00588','00589','00592','00593','00594','00596','00598','00599','00600') THEN 1 ELSE 0 END AS ent_honrada,
        CASE WHEN regexp_like(a.cod_cuenta_rcc, '^84.40[12345]') THEN 'gar_p'
             WHEN regexp_like(a.cod_cuenta_rcc, '^84.4(09|10)') THEN 'gar_np'
             ELSE 'Sin Garantia' END AS garantia,
        CASE
            WHEN a.tipo_credito IN ('01','02','03','04','05') THEN 'ins'
            WHEN a.tipo_credito IN ('06','07','08','09','10') THEN 'neg'
            WHEN a.tipo_credito IN ('11','12','13')           THEN 'con'
            ELSE 'otro'
        END AS flg_tipo_credito
    FROM (
        SELECT codmes, tip_doc, key_value, condicion, tipo_credito, cod_cuenta_rcc, cod_instit_financiera,
               cod_clasificacion_deudor, saldo
        FROM e_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes BETWEEN '202302' AND '202407'
          AND codmes   BETWEEN '202105' AND '202506'
    ) a
    INNER JOIN (
        SELECT tip_doc, key_value
        FROM morigbk_tag
        WHERE tag IN ('RESTO DD NEGOCIO','DESCUENTOS','FACTORING','LC NO UTILIZADA','LC DESCUENTO') AND ent_honrada=0
        GROUP BY 1,2
    ) b
    ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value
),
morigbk_saldo_hist AS (
WITH data_rcc AS (
    SELECT codmes, tip_doc, key_value, tipo_credito, cod_instit_financiera,
        max(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 AND tag IN ('RESTO DD','DESCUENTOS','FACTORING','REFINANCIADOS','LC NO UTILIZADA','LC DESCUENTO') THEN condicion ELSE null END) AS dm,
        sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 AND tag IN ('RESTO DD','DESCUENTOS','FACTORING','REFINANCIADOS','LC NO UTILIZADA','LC DESCUENTO') THEN saldo ELSE 0 END) AS saldo_mo,
        sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 8 AND 10 AND tag IN ('RESTO DD','DESCUENTOS','FACTORING','REFINANCIADOS','LC NO UTILIZADA','LC DESCUENTO') AND ent_honrada=0 THEN saldo ELSE 0 END) AS saldo_m0_entidad,
        sum(CASE WHEN garantia='gar_p'       THEN saldo ELSE null END) AS saldo_gar_p,
        sum(CASE WHEN garantia='gar_np'      THEN saldo ELSE null END) AS saldo_gar_np,
        sum(CASE WHEN garantia='Sin Garantia' THEN saldo ELSE null END) AS saldo_sg,
        sum(CASE WHEN flg_tipo_credito='ins' AND regexp_like(cod_cuenta_rcc, '^14.[13456]|^81.(302|925)') THEN saldo ELSE 0 END) AS deuda_ins,
        sum(CASE WHEN flg_tipo_credito='neg' AND regexp_like(cod_cuenta_rcc, '^14.[13456]|^81.(302|925)') THEN saldo ELSE 0 END) AS deuda_neg,
        sum(CASE WHEN flg_tipo_credito='con' AND regexp_like(cod_cuenta_rcc, '^14.[13456]|^81.(302|925)') THEN saldo ELSE 0 END) AS deuda_con
    FROM morigbk_rcc
    GROUP BY codmes, tip_doc, key_value, tipo_credito, cod_instit_financiera
),
info_consolid AS (
    SELECT a.codmes, a.tip_doc, a.key_value, b.cod_instit_financiera,
        max(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '0' month,'%Y%m') AS int) THEN dm ELSE 0 END) AS dm_m0,
        max(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '1' month,'%Y%m') AS int) THEN dm ELSE 0 END) AS dm_m1,
        max(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '2' month,'%Y%m') AS int) THEN dm ELSE 0 END) AS dm_m2,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '0' month,'%Y%m') AS int) THEN saldo_gar_p  ELSE 0 END) AS gar_p,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '0' month,'%Y%m') AS int) THEN saldo_gar_np ELSE 0 END) AS gar_np,
        max(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '3' month,'%Y%m') AS int) THEN dm ELSE 0 END) AS dm_m3,
        max(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '4' month,'%Y%m') AS int) THEN dm ELSE 0 END) AS dm_m4,
        max(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '5' month,'%Y%m') AS int) THEN dm ELSE 0 END) AS dm_m5,
        max(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '6' month,'%Y%m') AS int) THEN dm ELSE 0 END) AS dm_m6,
        max(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '7' month,'%Y%m') AS int) THEN dm ELSE 0 END) AS dm_m7,
        max(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '8' month,'%Y%m') AS int) THEN dm ELSE 0 END) AS dm_m8,
        max(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '9' month,'%Y%m') AS int) THEN dm ELSE 0 END) AS dm_m9,
        max(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '10' month,'%Y%m') AS int) THEN dm ELSE 0 END) AS dm_m10,
        max(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '11' month,'%Y%m') AS int) THEN dm ELSE 0 END) AS dm_m11,
        max(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '12' month,'%Y%m') AS int) THEN dm ELSE 0 END) AS dm_m12,
        min(CASE WHEN cast(b.tipo_credito AS int) BETWEEN 8 AND 10 THEN b.tipo_credito END) AS tipo_credito,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '0' month,'%Y%m') AS int) THEN saldo_m0_entidad ELSE 0 END) AS saldo_m0,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '1' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m1,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '2' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m2,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '3' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m3,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '4' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m4,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '5' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m5,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '6' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m6,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '7' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m7,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '8' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m8,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '9' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m9,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '10' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m10,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '11' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m11,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '12' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m12,
        sum(CASE WHEN cast(b.codmes AS int) >= cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '12' month,'%Y%m') AS int)
                  AND cast(b.codmes AS int) <= cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '1' month,'%Y%m') AS int) THEN deuda_ins ELSE null END) AS deuda_ins_u12m,
        sum(CASE WHEN cast(b.codmes AS int) >= cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '12' month,'%Y%m') AS int)
                  AND cast(b.codmes AS int) <= cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '1' month,'%Y%m') AS int) THEN deuda_neg ELSE null END) AS deuda_neg_u12m,
        sum(CASE WHEN cast(b.codmes AS int) >= cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '12' month,'%Y%m') AS int)
                  AND cast(b.codmes AS int) <= cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '1' month,'%Y%m') AS int) THEN deuda_con ELSE null END) AS deuda_con_u12m,
        sum(CASE WHEN cast(b.codmes AS int) >= cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '13' month,'%Y%m') AS int)
                  AND cast(b.codmes AS int) <= cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '2' month,'%Y%m') AS int) THEN deuda_ins ELSE null END) AS deuda_ins_u12m_v2,
        sum(CASE WHEN cast(b.codmes AS int) >= cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '13' month,'%Y%m') AS int)
                  AND cast(b.codmes AS int) <= cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '2' month,'%Y%m') AS int) THEN deuda_neg ELSE null END) AS deuda_neg_u12m_v2,
        sum(CASE WHEN cast(b.codmes AS int) >= cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '13' month,'%Y%m') AS int)
                  AND cast(b.codmes AS int) <= cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '2' month,'%Y%m') AS int) THEN deuda_con ELSE null END) AS deuda_con_u12m_v2
    FROM (
        SELECT codmes, tip_doc, key_value, cod_instit_financiera
        FROM morigbk_tag
        WHERE saldo>0 AND tag IN ('RESTO DD NEGOCIO','DESCUENTOS','FACTORING','LC NO UTILIZADA','LC DESCUENTO') AND ent_honrada=0
        GROUP BY 1,2,3,4
    ) a
    LEFT JOIN data_rcc b
      ON a.key_value = b.key_value
     AND a.tip_doc   = b.tip_doc
     AND a.cod_instit_financiera = b.cod_instit_financiera
     AND b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') - interval '13' month,'%Y%m') AND a.codmes
    GROUP BY a.codmes, a.tip_doc, a.key_value, b.cod_instit_financiera
),
max_saldo AS (
    SELECT a.*,
        greatest(saldo_m1,saldo_m2,saldo_m3,saldo_m4,saldo_m5,saldo_m6,saldo_m7,saldo_m8,saldo_m9,saldo_m10,saldo_m11,saldo_m12) AS max_saldo
    FROM (SELECT * FROM info_consolid WHERE cast(tipo_credito AS int) BETWEEN 8 AND 10) a
),
marca_perfil AS (
    SELECT a.*,
        CASE
            WHEN tipo_credito='08' AND (max_saldo<=1000000) THEN 1
            WHEN tipo_credito='09' AND (max_saldo<=1000000) THEN 1
            WHEN tipo_credito='10' AND (max_saldo>10000 AND max_saldo<=1000000) THEN 1
            ELSE 0
        END AS filtro_saldo
    FROM max_saldo a
)
    SELECT a.*,
        saldo_m1 AS saldo_mo_u1m,
        saldo_m1 + saldo_m2 AS saldo_mo_u2m,
        saldo_m1 + saldo_m2 + saldo_m3 AS saldo_mo_u3m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 AS saldo_mo_u4m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 AS saldo_mo_u5m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 + saldo_m6 AS saldo_mo_u6m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 + saldo_m6 + saldo_m7 AS saldo_mo_u7m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 + saldo_m6 + saldo_m7 + saldo_m8 AS saldo_mo_u8m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 + saldo_m6 + saldo_m7 + saldo_m8 + saldo_m9 AS saldo_mo_u9m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 + saldo_m6 + saldo_m7 + saldo_m8 + saldo_m9 + saldo_m10 AS saldo_mo_u10m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 + saldo_m6 + saldo_m7 + saldo_m8 + saldo_m9 + saldo_m10 + saldo_m11 AS saldo_mo_u11m,
        saldo_m1 + saldo_m2 + saldo_m3 + saldo_m4 + saldo_m5 + saldo_m6 + saldo_m7 + saldo_m8 + saldo_m9 + saldo_m10 + saldo_m11 + saldo_m12 AS saldo_mo_u1a,
        CASE WHEN gar_p>2  THEN '01.1 Garantia Preferida'
             WHEN gar_np>2 THEN '01. Garantia NoPreferida'
             ELSE '02. Sin Garantia' END AS flg_garantia
    FROM marca_perfil a
),
morigbk_altas AS (
WITH data_altas AS (
    SELECT a.*,
        CASE WHEN tipo_credito IN ('08','09','10') AND saldo_m0>0 THEN
            CASE
                WHEN (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m + saldo_mo_u6m + saldo_mo_u7m + saldo_mo_u8m + saldo_mo_u9m + saldo_mo_u10m + saldo_mo_u11m + saldo_mo_u1a) = 0 THEN 'A-12'
                WHEN (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m + saldo_mo_u6m + saldo_mo_u7m + saldo_mo_u8m + saldo_mo_u9m + saldo_mo_u10m + saldo_mo_u11m) = 0 THEN 'A-11'
                WHEN (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m + saldo_mo_u6m + saldo_mo_u7m + saldo_mo_u8m + saldo_mo_u9m + saldo_mo_u10m) = 0 THEN 'A-10'
                WHEN (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m + saldo_mo_u6m + saldo_mo_u7m + saldo_mo_u8m + saldo_mo_u9m) = 0 THEN 'A-09'
                WHEN (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m + saldo_mo_u6m + saldo_mo_u7m + saldo_mo_u8m) = 0 THEN 'A-08'
                WHEN (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m + saldo_mo_u6m + saldo_mo_u7m) = 0 THEN 'A-07'
                WHEN (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m + saldo_mo_u6m) = 0 THEN 'A-06'
                WHEN (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m + saldo_mo_u5m) = 0 THEN 'A-05'
                WHEN (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m + saldo_mo_u4m) = 0 THEN 'A-04'
                WHEN (saldo_mo_u1m + saldo_mo_u2m + saldo_mo_u3m) = 0 THEN 'A-03'
                WHEN (saldo_mo_u1m + saldo_mo_u2m) = 0 THEN 'A-02'
                WHEN (saldo_mo_u1m) = 0 THEN 'A-01'
                ELSE 'A-00'
            END
        ELSE 'A-otro' END AS altas
    FROM morigbk_saldo_hist a
),
marca_entidades AS (
    SELECT a.*,
        CASE WHEN cod_instit_financiera='00002' THEN 'IBK' ELSE 'OTRO' END AS marca_entidad
    FROM data_altas a
),
marca_altas AS (
    SELECT a.*,
        CASE WHEN altas='A-12' THEN 1 ELSE 0 END AS alta12,
        CASE WHEN altas IN ('A-06','A-07','A-08','A-09','A-10','A-11','A-12') THEN 1 ELSE 0 END AS alta6,
        CASE WHEN altas IN ('A-02','A-03','A-04','A-05','A-06','A-07','A-08','A-09','A-10','A-11','A-12') THEN 1 ELSE 0 END AS alta2
    FROM marca_entidades a
)
    SELECT codmes, tip_doc, key_value, cod_instit_financiera, marca_entidad,
        gar_p, gar_np, tipo_credito, flg_garantia, altas, alta12, alta6, alta2,
        dm_m0, dm_m1, dm_m2, max_saldo, filtro_saldo, saldo_m0,
        deuda_ins_u12m, deuda_neg_u12m, deuda_con_u12m,
        deuda_ins_u12m_v2, deuda_neg_u12m_v2, deuda_con_u12m_v2
    FROM marca_altas
),
morigbk_rcc_bank AS (
    SELECT DISTINCT a.codmes, a.tip_doc, a.key_value, a.condicion, a.tipo_credito, a.cod_cuenta_rcc,
           a.cod_instit_financiera, a.cod_clasificacion_deudor, a.saldo,
        CASE
            WHEN substr(a.cod_cuenta_rcc,1,2)='14' AND substr(a.cod_cuenta_rcc,4,1) IN ('1','3','4','5','6') THEN
                CASE
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='05' THEN 'DESCUENTOS'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='10' THEN 'FACTORING'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='04' THEN 'SOBREGIRO'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,7,2)='01' THEN 'AVANCE CC'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,4,1)='4' THEN 'REFINANCIADOS'
                    ELSE 'RESTO DD'
                END
            WHEN substr(a.cod_cuenta_rcc,1,2)='72' AND substr(a.cod_cuenta_rcc,4,1)='5' THEN
                CASE
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,5,2)='02' THEN 'LC DESCUENTO'
                    WHEN (cast(a.tipo_credito AS int) BETWEEN 1 AND 10) AND substr(a.cod_cuenta_rcc,5,2) IN ('03','06','08','09') THEN 'LC NO UTILIZADA'
                    ELSE 'RESTO LC'
                END
        ELSE 'OTROS' END AS tag,
        CASE WHEN a.cod_instit_financiera IN ('00469','00470','00472','00477','00478','00497','00498','00499','00500','00508',
                    '00509','00510','00512','00513','00514','00516','00517','00518','00519','00580','00581','00582','00583',
                    '00587','00588','00589','00592','00593','00594','00596','00598','00599','00600') THEN 1 ELSE 0 END AS ent_honrada,
        CASE WHEN regexp_like(a.cod_cuenta_rcc, '^84.40[12345]') THEN 'gar_p'
             WHEN regexp_like(a.cod_cuenta_rcc, '^84.4(09|10)') THEN 'gar_np'
             ELSE 'Sin Garantia' END AS garantia,
        CASE
            WHEN a.tipo_credito IN ('01','02','03','04','05') THEN 'ins'
            WHEN a.tipo_credito IN ('06','07','08','09','10') THEN 'neg'
            WHEN a.tipo_credito IN ('11','12','13')           THEN 'con'
            ELSE 'otro'
        END AS flg_tipo_credito
    FROM (
        SELECT codmes, tip_doc, key_value, condicion, tipo_credito, cod_cuenta_rcc, cod_instit_financiera,
               cod_clasificacion_deudor, saldo
        FROM e_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes BETWEEN '202302' AND '202407'
          AND codmes   BETWEEN '202105' AND '202506'
    ) a
    INNER JOIN (
        SELECT tip_doc, key_value FROM morigbk_altas WHERE alta2=1 GROUP BY 1,2
    ) b
    ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value
),
morigbk_saldo_hist_bank AS (
WITH data_rcc_bank AS (
    SELECT codmes, tip_doc, key_value,
        sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 THEN saldo ELSE 0 END) AS saldo_mo
    FROM morigbk_rcc_bank
    GROUP BY codmes, tip_doc, key_value
),
info_consolid_bank AS (
    SELECT a.codmes, a.tip_doc, a.key_value,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '0' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m0,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '1' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m1,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '2' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m2,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '3' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m3,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '4' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m4,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '5' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m5,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '6' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m6,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '7' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m7,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '8' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m8,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '9' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m9,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '10' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m10,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '11' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m11,
        sum(CASE WHEN cast(b.codmes AS int) = cast(date_format(date_parse(cast(a.codmes AS varchar),'%Y%m') - interval '12' month,'%Y%m') AS int) THEN saldo_mo ELSE 0 END) AS saldo_m12
    FROM (SELECT codmes, tip_doc, key_value FROM morigbk_altas WHERE alta2=1 GROUP BY 1,2,3) a
    LEFT JOIN data_rcc_bank b
      ON a.key_value = b.key_value
     AND a.tip_doc   = b.tip_doc
     AND b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') - interval '13' month,'%Y%m') AND a.codmes
    GROUP BY a.codmes, a.tip_doc, a.key_value
)
    SELECT a.*,
        greatest(saldo_m1,saldo_m2,saldo_m3,saldo_m4,saldo_m5,saldo_m6,saldo_m7,saldo_m8,saldo_m9,saldo_m10,saldo_m11,saldo_m12) AS max_saldo
    FROM info_consolid_bank a
),
base_altas_cliente AS (
    SELECT
        a.*,
        b.cod_instit_financiera,
        c.nombre_instit_financiera,
        b.marca_entidad,
        b.tipo_credito,
        b.altas, b.alta12, b.alta6, b.alta2,
        b.flg_garantia, b.gar_p, b.gar_np, b.filtro_saldo,
        b.dm_m0, b.dm_m1, b.dm_m2,
        b.max_saldo AS max_saldo_ent,
        b.saldo_m0  AS saldo_m0_ent,
        b.deuda_ins_u12m, b.deuda_neg_u12m, b.deuda_con_u12m,
        b.deuda_ins_u12m_v2, b.deuda_neg_u12m_v2, b.deuda_con_u12m_v2,
        CASE WHEN b.cod_instit_financiera   IS NULL THEN 1 ELSE 0 END AS falla_entidad_alta,
        CASE WHEN c.nombre_instit_financiera IS NULL THEN 1 ELSE 0 END AS falla_nombre_inst,
        RANK() OVER (PARTITION BY a.codmes, a.tip_doc, a.key_value
                     ORDER BY COALESCE(c.cod_instit_financiera, b.cod_instit_financiera) ASC) AS rank
    FROM morigbk_saldo_hist_bank a
    LEFT JOIN (SELECT * FROM morigbk_altas WHERE alta2 = 1) b
      ON a.codmes = b.codmes AND a.key_value = b.key_value AND a.tip_doc = b.tip_doc
    LEFT JOIN e_perm_aws.t_dim_inst_fin_rsk c
      ON c.cod_instit_financiera = b.cod_instit_financiera
    WHERE a.max_saldo > 0
      AND COALESCE(c.nombre_instit_financiera,'SIN NOMBRE') NOT IN (
            'BANCO AGROPECUARIO','BANCO DE LA NACION',
            'CAJA RURAL DE AHORRO Y CREDITO SIPAN S A','LEASING TOTAL S A','VALOR NO ENVIADO POR IBK')
      AND UPPER(COALESCE(c.nombre_instit_financiera,'SIN NOMBRE')) NOT LIKE 'BBVA CONSUMER%'
)
SELECT *,
    codmes AS p_codmes,
    date_format(date_parse(codmes,'%Y%m') - interval '1' month,'%Y%m') AS codmes_score
FROM base_altas_cliente
WHERE rank = 1

) z
