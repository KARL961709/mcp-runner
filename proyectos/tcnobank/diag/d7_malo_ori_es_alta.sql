-- ============================================================================
-- D7. LOS MALO EN EL ORIGEN SON ALTAS DE VERDAD
--   scan: disc_model_owner.ds_adm_vcnbank_tc_cal U _05_rcc_agg en codmes y en [m-24, m-13]
--   ancla: no se puede estar atrasado en una tarjeta abierta este mes. Un dm alto en m0 o
--          una TC en la misma entidad justo fuera de la ventana de 12 meses delata re-reporte
-- ============================================================================
WITH g AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad, f_malo_ori, target_12m,
           date_format(date_add('month', -24, date_parse(codmes_mrm, '%Y%m')), '%Y%m')  AS m24,
           date_format(date_add('month', -13, date_parse(codmes_mrm, '%Y%m')), '%Y%m')  AS m13
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE flg_calib = 1 AND flg_clean_prod = 1
),
d AS (
    SELECT g.f_malo_ori,
           g.target_12m,
           max(CASE WHEN a.codmes = g.codmes_mrm THEN a.dm_tc END)                      AS dm_m0,
           max(CASE WHEN a.codmes BETWEEN g.m24 AND g.m13 AND a.flg_tc = 1
                    THEN 1 ELSE 0 END)                                                  AS tc_13_24m
    FROM g
    LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg a
           ON a.tip_doc = g.tip_doc AND a.key_value = g.id_value AND a.entidad = g.entidad
          AND a.codmes BETWEEN g.m24 AND g.codmes_mrm
    GROUP BY g.codmes_mrm, g.tip_doc, g.id_value, g.entidad, g.f_malo_ori, g.target_12m
)
SELECT CASE WHEN f_malo_ori = 1 THEN '2.malo en el origen' ELSE '1.clean vigente' END   AS grupo,
       CASE WHEN dm_m0 IS NULL THEN '0.sin dato'
            WHEN dm_m0 =   0   THEN '1.dm 0'
            WHEN dm_m0 <=  8   THEN '2.dm 1 a 8'
            WHEN dm_m0 <= 30   THEN '3.dm 9 a 30'
            WHEN dm_m0 <= 60   THEN '4.dm 31 a 60'
            WHEN dm_m0 <= 90   THEN '5.dm 61 a 90'
            ELSE                    '6.dm mayor a 90' END                               AS tramo_dm_m0,
       count(*)                                                                         AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY f_malo_ori), 3)        AS pct_del_grupo,
       sum(tc_13_24m)                                                                   AS n_con_tc_13_24m,
       round(100.0 * avg(CAST(tc_13_24m AS DOUBLE)), 3)                                 AS pct_con_tc_13_24m,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m
FROM d
GROUP BY 1, 2
ORDER BY 1, 2
