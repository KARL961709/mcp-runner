-- 105_estabilidad_insumos_cal.sql | estabilidad de los insumos de la calibracion por trimestre, sobre la poblacion de ajuste. Si pd_raw o la mezcla de personeria derivan, los coeficientes promedian regimenes distintos en vez de un fenomeno estable
SELECT CAST(SUBSTRING(codmes, 1, 4) AS INT) * 10
         + ((CAST(SUBSTRING(codmes, 5, 2) AS INT) - 1) / 3 + 1)                     AS trimestre,
       count(1)                                                                     AS n,
       round(100.0 * avg(COALESCE(flg_ppjj, 0)), 2)                                 AS pjj_pct,
       round(100.0 * avg(pd_raw), 4)                                                AS pd_raw_media,
       round(100.0 * approx_percentile(pd_raw, 0.10), 4)                            AS pd_p10,
       round(100.0 * approx_percentile(pd_raw, 0.50), 4)                            AS pd_p50,
       round(100.0 * approx_percentile(pd_raw, 0.90), 4)                            AS pd_p90,
       round(100.0 * max(pd_raw), 4)                                                AS pd_max,
       round(100.0 * avg(TRY_CAST(target_12m AS DOUBLE)), 4)                        AS rd12_pct,
       round(100.0 * avg(prob_modelo_cal), 4)                                       AS pd_cal_pct,
       round(max(fhat), 6)                                                          AS fhat,
       sum(CASE WHEN flg_clean_calib = 1 THEN 1 ELSE 0 END)                         AS n_clean,
       sum(CASE WHEN flg_clean_calib = 0 THEN 1 ELSE 0 END)                         AS n_dirty
FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
WHERE flg_calib = 1
  AND entidad = 'IBK'
  AND target_12m IS NOT NULL
GROUP BY CAST(SUBSTRING(codmes, 1, 4) AS INT) * 10
         + ((CAST(SUBSTRING(codmes, 5, 2) AS INT) - 1) / 3 + 1)
ORDER BY trimestre
