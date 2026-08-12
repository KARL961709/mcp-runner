-- ============================================================================
-- D15. QUE REGLA SEPARA LAS NO-ORIGINACIONES SIN DEPENDER DE TNG
--   scan: cal U tng_altas_ssff_rsk U tng_altas_ibk_rsk U _05_rcc_agg [m-24,m-13] y m0
--   ancla: tng solo existe desde 202201 y la serie arranca en 201902, asi que la regla
--          tiene que ser estructural. Se calibra contra tng en el solape. malo_ori ya
--          captura 77 por ciento del solo_rcc de BCP: falta saber que es el resto
-- ============================================================================
WITH d AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad,
           max(ctrl_malo_ori_m0) AS malo_ori,
           max(target_12m)       AS target_12m,
           max(flg_clean)        AS flg_clean,
           date_format(date_add('month', -24, date_parse(max(codmes_mrm), '%Y%m')), '%Y%m') AS m24,
           date_format(date_add('month', -13, date_parse(max(codmes_mrm), '%Y%m')), '%Y%m') AS m13
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE codmes_mrm BETWEEN '202201' AND '202506'
      AND entidad IN ('00001','00002','00004','00006','00142')
    GROUP BY codmes_mrm, tip_doc, id_value, entidad
),
o AS (
    SELECT p_codmes AS codmes_mrm, tipdoc AS tip_doc, key_value AS id_value,
           ltrim(rtrim(codempresa)) AS entidad
    FROM e_perm_aws.tng_altas_ssff_rsk
    WHERE p_codmes BETWEEN '202201' AND '202506'
      AND ltrim(rtrim(codempresa)) IN ('00001','00004','00006','00142')
    UNION
    SELECT p_codmes, ca_tip_doc, key_value, '00002'
    FROM e_perm_aws.tng_altas_ibk_rsk
    WHERE p_codmes BETWEEN '202201' AND '202506'
),
x AS (
    SELECT d.entidad,
           d.malo_ori,
           d.target_12m,
           d.flg_clean,
           CASE WHEN o.id_value IS NOT NULL THEN 1 ELSE 0 END                           AS en_tng,
           max(CASE WHEN r.codmes BETWEEN d.m24 AND d.m13 AND r.flg_tc = 1
                    THEN 1 ELSE 0 END)                                                  AS tc_13_24m,
           max(CASE WHEN r.codmes = d.codmes_mrm THEN r.saldo_tc END)                   AS saldo_m0
    FROM d
    LEFT JOIN o
           ON o.codmes_mrm = d.codmes_mrm AND o.tip_doc = d.tip_doc
          AND o.id_value = d.id_value AND o.entidad = d.entidad
    LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg r
           ON r.tip_doc = d.tip_doc AND r.key_value = d.id_value AND r.entidad = d.entidad
          AND r.codmes BETWEEN d.m24 AND d.codmes_mrm
    GROUP BY d.codmes_mrm, d.tip_doc, d.id_value, d.entidad, d.malo_ori,
             d.target_12m, d.flg_clean, CASE WHEN o.id_value IS NOT NULL THEN 1 ELSE 0 END
)
SELECT entidad,
       en_tng,
       malo_ori,
       tc_13_24m,
       count(*)                                                                         AS n,
       sum(CASE WHEN flg_clean = 1 THEN 1 ELSE 0 END)                                   AS n_clean,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       round(avg(saldo_m0), 0)                                                          AS saldo_m0_medio
FROM x
WHERE entidad IN ('00001','00006')
GROUP BY entidad, en_tng, malo_ori, tc_13_24m
ORDER BY entidad, en_tng, malo_ori, tc_13_24m
