-- ============================================================================
-- D8. SERIE MENSUAL DE LA RD CON Y SIN MALO EN EL ORIGEN
--   scan: disc_model_owner.ds_adm_vcnbank_tc_cal, lee la tabla PREVIA a la reconstruccion
--   ancla: si la brecha es de nivel la absorbe el intercepto. Si se mueve con el ciclo,
--          la decision cambia el modelo macro y no solo la LRA
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
SELECT codmes_mrm,
       count(*)                                                                         AS n_prod,
       sum(malo_ori)                                                                     AS n_malo_ori,
       round(100.0 * avg(CAST(malo_ori AS DOUBLE)), 4)                                   AS pct_malo_ori,
       round(100.0 * avg(CASE WHEN malo_ori = 0
                              THEN CAST(target_12m AS DOUBLE) END), 4)                   AS rd_clean,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                 AS rd_prod,
       round(100.0 * avg(CAST(target_12m AS DOUBLE))
           - 100.0 * avg(CASE WHEN malo_ori = 0
                              THEN CAST(target_12m AS DOUBLE) END), 4)                   AS delta_pp,
       round(100.0 * avg(pd_raw), 4)                                                     AS pd_raw_media
FROM b
GROUP BY codmes_mrm
ORDER BY codmes_mrm
