-- 1t3_h_po.sql | saldo sistema y entidad alta | escribe 201906-202105 lee 201805-202105
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_po_t3 AS
WITH data_rcc_bank AS (
    SELECT codmes, tip_doc, key_value,
        sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10 THEN saldo ELSE 0 END) AS saldo_mo
    FROM (
        SELECT DISTINCT a.codmes, a.tip_doc, a.key_value, a.condicion, a.tipo_credito, a.cod_cuenta_rcc,
               a.cod_instit_financiera, a.cod_clasificacion_deudor, a.saldo
        FROM (
            SELECT codmes, tip_doc, key_value, condicion, tipo_credito, cod_cuenta_rcc, cod_instit_financiera,
                   cod_clasificacion_deudor, saldo
            FROM d_perm_aws.t_fact_report_rcc_rsk
            WHERE p_codmes BETWEEN '201803' AND '201812'
              AND codmes   BETWEEN '201805' AND '202105'
            UNION ALL
            SELECT codmes, tip_doc, key_value, condicion, tipo_credito, cod_cuenta_rcc, cod_instit_financiera,
                   cod_clasificacion_deudor, saldo
            FROM e_perm_aws.t_fact_report_rcc_rsk
            WHERE p_codmes BETWEEN '201901' AND '202107'
              AND codmes   BETWEEN '201805' AND '202105'
        ) a
        INNER JOIN (
            SELECT tip_doc, key_value
            FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_altas
            WHERE alta2 = 1
            GROUP BY 1,2
        ) b
        ON a.tip_doc = b.tip_doc AND a.key_value = b.key_value
    ) r
    GROUP BY 1,2,3
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
    FROM (
        SELECT codmes, tip_doc, key_value
        FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_altas
        WHERE alta2 = 1
        GROUP BY 1,2,3
    ) a
    LEFT JOIN data_rcc_bank b
      ON a.key_value = b.key_value
     AND a.tip_doc   = b.tip_doc
     AND b.codmes BETWEEN date_format(date_parse(a.codmes,'%Y%m') - interval '13' month,'%Y%m') AND a.codmes
    GROUP BY a.codmes, a.tip_doc, a.key_value
),
bank AS (
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
        ROW_NUMBER() OVER (PARTITION BY a.codmes, a.tip_doc, a.key_value
                     ORDER BY COALESCE(c.cod_instit_financiera, b.cod_instit_financiera) ASC) AS rn
    FROM bank a
    LEFT JOIN (SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_altas WHERE alta2 = 1) b
      ON a.codmes = b.codmes AND a.key_value = b.key_value AND a.tip_doc = b.tip_doc
    LEFT JOIN (SELECT cod_instit_financiera, max(nombre_instit_financiera) AS nombre_instit_financiera
               FROM e_perm_aws.t_dim_inst_fin_rsk GROUP BY 1) c
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
WHERE rn = 1
