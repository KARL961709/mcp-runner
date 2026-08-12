-- ============================================================================
-- D8. SERIE MENSUAL DE LA RD CON Y SIN MALO EN EL ORIGEN
--   scan: disc_model_owner.ds_adm_vcnbank_tc_cal sobre flg_calib = 1 y flg_clean_prod = 1
--   ancla: si la brecha es estable el efecto es de nivel y lo absorbe el intercepto. Si
--          se mueve con el ciclo, la decision cambia el modelo macro y no solo la LRA
-- ============================================================================
SELECT codmes_mrm,
       count(*)                                                                        AS n_prod,
       sum(CASE WHEN f_malo_ori = 0 THEN 1 ELSE 0 END)                                 AS n_clean,
       sum(f_malo_ori)                                                                 AS n_malo_ori,
       round(100.0 * avg(CAST(f_malo_ori AS DOUBLE)), 4)                               AS pct_malo_ori,
       round(100.0 * avg(CASE WHEN f_malo_ori = 0
                              THEN CAST(target_12m AS DOUBLE) END), 4)                 AS rd_clean,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                               AS rd_prod,
       round(100.0 * avg(CAST(target_12m AS DOUBLE))
           - 100.0 * avg(CASE WHEN f_malo_ori = 0
                              THEN CAST(target_12m AS DOUBLE) END), 4)                 AS delta_pp,
       round(100.0 * avg(pd_raw), 4)                                                   AS pd_raw_media
FROM disc_model_owner.ds_adm_vcnbank_tc_cal
WHERE flg_calib = 1 AND flg_clean_prod = 1
GROUP BY codmes_mrm
ORDER BY codmes_mrm
