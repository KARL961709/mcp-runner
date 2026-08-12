-- ============================================================================
-- D6. CUANTO INFLA LA MORA INCLUIR MALO EN EL ORIGEN
--   scan: disc_model_owner.ds_adm_vcnbank_tc_cal, lee la tabla PREVIA a la reconstruccion
--   ancla: hoy f_malo_ori sale de m2 y es cero, asi que flg_clean = 1 ya es la base de
--          produccion. ctrl_malo_ori_m0 marca al grupo. Se dedupea por las 4 llaves
-- ============================================================================
WITH b AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad,
           max(ctrl_malo_ori_m0) AS malo_ori,
           max(target_03m) AS target_03m, max(target_06m) AS target_06m,
           max(target_12m) AS target_12m, max(max_dm_fut) AS max_dm_fut, max(pd_raw) AS pd_raw
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE flg_calib = 1 AND flg_clean = 1
    GROUP BY codmes_mrm, tip_doc, id_value, entidad
)
SELECT CASE WHEN GROUPING(malo_ori) = 1 THEN '3.pooled produccion'
            WHEN malo_ori = 1           THEN '2.malo en el origen'
            ELSE                             '1.clean sin malo_ori' END                 AS grupo,
       count(*)                                                                         AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 4)                                AS pct,
       count(target_12m)                                                                 AS n_evaluable,
       sum(target_12m)                                                                   AS n_malo,
       round(100.0 * avg(CAST(target_03m AS DOUBLE)), 4)                                 AS rd_03m,
       round(100.0 * avg(CAST(target_06m AS DOUBLE)), 4)                                 AS rd_06m,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                 AS rd_12m,
       round(100.0 * avg(pd_raw), 4)                                                     AS pd_raw_media,
       round(avg(max_dm_fut), 2)                                                         AS dm_fut_medio
FROM b
GROUP BY GROUPING SETS ((malo_ori), ())
ORDER BY grupo
