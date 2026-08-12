-- ============================================================================
-- D4. COMPORTAMIENTO DE MALO EN EL ORIGEN MEDIDO EN M0
-- ============================================================================
SELECT CASE WHEN ctrl_malo_ori_m0 = 1 THEN '1.dispara malo_ori_m0'
            ELSE                           '2.no dispara' END                          AS grupo,
       count(*)                                                                        AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 4)                              AS pct_universo,
       count(target_12m)                                                               AS n_evaluable,
       sum(target_12m)                                                                 AS n_malo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                               AS bad_rate,
       sum(CASE WHEN flg_clean = 1 THEN 1 ELSE 0 END)                                  AS n_hoy_clean,
       round(100.0 * avg(CASE WHEN flg_clean = 1
                              THEN CAST(target_12m AS DOUBLE) END), 4)                 AS bad_rate_en_clean,
       round(avg(max_dm_fut), 2)                                                       AS dm_fut_medio
FROM disc_model_owner.ds_adm_vcnbank_tc_cal
GROUP BY 1
ORDER BY 1
