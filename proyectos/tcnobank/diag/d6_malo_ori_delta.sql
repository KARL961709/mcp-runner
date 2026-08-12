-- ============================================================================
-- D6. CUANTO INFLA LA MORA INCLUIR MALO EN EL ORIGEN
--   scan: disc_model_owner.ds_adm_vcnbank_tc_cal sobre flg_calib = 1 y flg_clean_prod = 1
--   ancla: flg_clean_prod es clean SIN f_malo_ori. El pooled es la base que produccion
--          si puede replicar, porque en campania no se observa la mora de m0
-- ============================================================================
SELECT CASE WHEN GROUPING(f_malo_ori) = 1 THEN '3.pooled produccion'
            WHEN f_malo_ori = 1           THEN '2.malo en el origen'
            ELSE                               '1.clean vigente' END                   AS grupo,
       count(*)                                                                        AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 4)                              AS pct,
       count(target_12m)                                                               AS n_evaluable,
       sum(target_12m)                                                                 AS n_malo,
       round(100.0 * avg(CAST(target_03m AS DOUBLE)), 4)                               AS rd_03m,
       round(100.0 * avg(CAST(target_06m AS DOUBLE)), 4)                               AS rd_06m,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                               AS rd_12m,
       round(100.0 * avg(pd_raw), 4)                                                   AS pd_raw_media,
       round(avg(max_dm_fut), 2)                                                       AS dm_fut_medio
FROM disc_model_owner.ds_adm_vcnbank_tc_cal
WHERE flg_calib = 1 AND flg_clean_prod = 1
GROUP BY GROUPING SETS ((f_malo_ori), ())
ORDER BY grupo
