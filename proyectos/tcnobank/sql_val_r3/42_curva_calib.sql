-- 42_curva_calib.sql | curva de calibracion sobre la ventana madura: pd cruda contra tasa observada por decil de pd, que es el insumo del ajuste probit con shift y pendiente
SELECT ntile_pd                                                       AS decil_pd,
       count(*)                                                       AS n,
       round(100.0 * min(pd_raw), 4)                                  AS pd_raw_min,
       round(100.0 * avg(pd_raw), 4)                                  AS pd_raw_media,
       round(100.0 * max(pd_raw), 4)                                  AS pd_raw_max,
       sum(target_12m)                                                AS n_malo_pub,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)              AS rd_pub,
       round(100.0 * avg(CAST(target_12m_full AS DOUBLE)), 4)         AS rd_full,
       round(avg(scr_nuevo), 1)                                       AS scr_nuevo_medio,
       round(100.0 * avg(pd_cal_pub), 4)                              AS pd_cal_pub
FROM (
    SELECT ntile(10) OVER (ORDER BY pd_raw) AS ntile_pd,
           pd_raw,
           pd_cal_pub,
           scr_nuevo,
           target_12m,
           target_12m_full
    FROM disc_model_owner.ds_tcnobank_calib_v1
    WHERE flg_maduro = 1
      AND prelacion_12m = 1
      AND pd_raw IS NOT NULL
      AND target_12m IS NOT NULL
) x
GROUP BY ntile_pd
ORDER BY ntile_pd
