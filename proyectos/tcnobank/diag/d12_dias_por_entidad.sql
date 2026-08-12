-- ============================================================================
-- D12. CUANTOS DIAS DE ATRASO TIENEN EN EL MES DEL ALTA Y EN QUE ENTIDAD
--   scan: ds_adm_vcnbank_tc_cal U _05_rcc_agg en codmes, ventana de calibracion
--   ancla: dm_tc > 0 es UN dia, no sesenta. Si BCP se concentra en el tramo bajo y su
--          bad rate igual es 60 por ciento, el atraso no es la causa sino un sintoma
-- ============================================================================
WITH b AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad,
           max(ctrl_malo_ori_m0) AS malo_ori,
           max(target_12m)       AS target_12m
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE flg_calib = 1 AND flg_clean = 1
    GROUP BY codmes_mrm, tip_doc, id_value, entidad
),
a AS (
    SELECT b.entidad, b.malo_ori, b.target_12m, r.dm_tc
    FROM b
    LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg r
           ON r.tip_doc = b.tip_doc AND r.key_value = b.id_value
          AND r.entidad = b.entidad AND r.codmes = b.codmes_mrm
)
SELECT entidad,
       CASE WHEN dm_tc IS NULL THEN '0.sin dato'
            WHEN dm_tc =  0    THEN '1.cero'
            WHEN dm_tc <=  8   THEN '2.uno a ocho'
            WHEN dm_tc <= 30   THEN '3.nueve a treinta'
            WHEN dm_tc <= 60   THEN '4.treintaiuno a sesenta'
            WHEN dm_tc <= 90   THEN '5.sesentaiuno a noventa'
            ELSE                    '6.mayor a noventa' END                             AS tramo_dm_m0,
       count(*)                                                                         AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY entidad), 4)           AS pct_de_la_entidad,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m
FROM a
GROUP BY entidad,
         CASE WHEN dm_tc IS NULL THEN '0.sin dato'
              WHEN dm_tc =  0    THEN '1.cero'
              WHEN dm_tc <=  8   THEN '2.uno a ocho'
              WHEN dm_tc <= 30   THEN '3.nueve a treinta'
              WHEN dm_tc <= 60   THEN '4.treintaiuno a sesenta'
              WHEN dm_tc <= 90   THEN '5.sesentaiuno a noventa'
              ELSE                    '6.mayor a noventa' END
ORDER BY entidad, tramo_dm_m0
