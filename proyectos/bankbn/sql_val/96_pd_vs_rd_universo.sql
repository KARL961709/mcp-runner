-- 96_pd_vs_rd_universo.sql | separa el universo de ajuste del bucket 99. La calibracion solo puede juzgarse en flg_clean_calib IN (0,1) con entidad IBK: todo lo demas es poblacion que el ajuste nunca vio
SELECT CASE WHEN flg_clean_calib = 99 THEN 'C_99_no_visto'
            WHEN flg_clean_calib = 1  THEN 'A_calib_clean'
            ELSE 'B_calib_dirty' END                                       AS universo,
       entidad,
       personeria,
       count(1)                                                            AS n,
       sum(TRY_CAST(target_12m AS INTEGER))                                AS malos,
       round(100.0 * avg(TRY_CAST(target_12m AS DOUBLE)), 3)               AS rd12_pct,
       round(100.0 * avg(prob_modelo_cal), 3)                              AS pd_cal_pct,
       round(100.0 * (avg(prob_modelo_cal)
             / nullif(avg(TRY_CAST(target_12m AS DOUBLE)), 0) - 1), 1)     AS ec_pct
FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
WHERE prob_modelo_cal IS NOT NULL
  AND target_12m IS NOT NULL
  AND entidad IN ('IBK', 'BCP', 'BBVA', 'SCOTIA')
GROUP BY CASE WHEN flg_clean_calib = 99 THEN 'C_99_no_visto'
              WHEN flg_clean_calib = 1  THEN 'A_calib_clean'
              ELSE 'B_calib_dirty' END,
         entidad,
         personeria
ORDER BY universo, entidad, personeria
