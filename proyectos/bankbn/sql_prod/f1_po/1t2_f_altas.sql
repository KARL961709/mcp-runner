-- 1t2_f_altas.sql | pivot 13m y clasifica altas | escribe 201706-201905 lee tmp 201605-201905
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_tmp_altas AS
WITH info_consolid AS (
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
        FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_tag
        WHERE flg_saldo_pos = 1
    ) a
    LEFT JOIN disc_model_owner.ds_adm_bpe_bankbn_tmp_rcc b
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
),
saldo_hist AS (
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
data_altas AS (
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
    FROM saldo_hist a
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
