-- ============================================================================
-- D5. DE DONDE SALE EL 75 POR CIENTO SIN SCORE
--   scan: disc_model_owner.ds_adm_vcnbank_tc_cal en [202303,202506]
--   ancla: si el score solo existe para el alcance del modelo, el bucket 3 sube cerca de 100
-- ============================================================================
SELECT CASE WHEN f_banc_u12m = 1 THEN '1.bancarizado u12m'
            WHEN f_entidades = 1 THEN '2.entidad fuera de alcance'
            WHEN f_edad_nomatch = 1 THEN '3.sin match reniec'
            ELSE                      '4.en alcance' END                               AS bucket,
       count(*)                                                                        AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 3)                              AS pct_universo,
       sum(CASE WHEN pd_raw IS NOT NULL THEN 1 ELSE 0 END)                             AS n_con_score,
       round(100.0 * avg(CASE WHEN pd_raw IS NOT NULL THEN 1.0 ELSE 0.0 END), 3)       AS pct_con_score,
       round(100.0 * avg(CASE WHEN pd_raw IS NOT NULL THEN CAST(target_12m AS DOUBLE) END), 4) AS rd_con_score,
       round(100.0 * avg(CASE WHEN pd_raw IS NULL     THEN CAST(target_12m AS DOUBLE) END), 4) AS rd_sin_score
FROM disc_model_owner.ds_adm_vcnbank_tc_cal
WHERE codmes_mrm BETWEEN '202303' AND '202506'
GROUP BY 1
ORDER BY 1
