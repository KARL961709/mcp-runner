-- c1_insumo_calibracion.sql | la tabla que consume la calibracion: RD, PD y residuo logit por cosecha y personeria
SELECT CAST(codmes AS VARCHAR)                                              AS codmes,
       CASE WHEN COALESCE(flg_ppjj,0) = 1 THEN 'PPJJ' ELSE 'PPNN' END       AS personeria,
       CASE WHEN flg_clean = 1 THEN 'clean' ELSE 'dirty' END                AS bucket,
       count(1)                                                             AS n,
       sum(target_12m)                                                      AS malos,
       round(100.0 * sum(target_12m) / count(1), 4)                         AS rd12_pct,
       round(100.0 * avg(pd_raw), 4)                                        AS pd_vig_pct,
       round(100.0 * approx_percentile(pd_raw, 0.5), 4)                     AS pd_p50_pct,
       round(ln(nullif(1.0 * sum(target_12m) / count(1), 0)
              / nullif(1 - 1.0 * sum(target_12m) / count(1), 0))
           - ln(nullif(avg(pd_raw), 0) / nullif(1 - avg(pd_raw), 0)), 5)    AS residuo_logit,
       round(100.0 * min(pd_raw), 4)                                        AS pd_min_pct,
       round(100.0 * max(pd_raw), 4)                                        AS pd_max_pct
FROM disc_model_owner.ds_adm_bpe_bankbn_cal
WHERE flg_calib = 1
  AND entidad = 'IBK'
GROUP BY CAST(codmes AS VARCHAR),
         CASE WHEN COALESCE(flg_ppjj,0) = 1 THEN 'PPJJ' ELSE 'PPNN' END,
         CASE WHEN flg_clean = 1 THEN 'clean' ELSE 'dirty' END
ORDER BY personeria, bucket, codmes
