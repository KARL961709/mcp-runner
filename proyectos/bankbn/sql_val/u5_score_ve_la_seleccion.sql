-- u5_score_ve_la_seleccion.sql | el marcado de IBK cae a la mitad que el de SSFF: el score ya lo ve o es info fuera del modelo?
SELECT CASE WHEN entidad = 'IBK' THEN '1_IBK' ELSE '2_SSFF' END  AS grupo,
       CASE WHEN flg_clean = 1 THEN 'clean' ELSE 'dirty' END     AS bucket,
       count(1)                                                  AS n,
       sum(target_12m)                                           AS malos,
       round(100.0 * sum(target_12m) / count(1), 2)              AS badrate_pct,
       round(100.0 * avg(pd_raw), 2)                             AS pd_media_pct,
       round(100.0 * sum(target_12m) / count(1) - 100.0 * avg(pd_raw), 2) AS gap_pp,
       round(100.0 * approx_percentile(pd_raw, 0.5), 2)          AS pd_p50_pct
FROM disc_model_owner.ds_adm_bpe_bankbn_cal
WHERE flg_calib = 1
  AND flg_clean IN (0, 1)
GROUP BY CASE WHEN entidad = 'IBK' THEN '1_IBK' ELSE '2_SSFF' END,
         CASE WHEN flg_clean = 1 THEN 'clean' ELSE 'dirty' END
ORDER BY grupo, bucket
