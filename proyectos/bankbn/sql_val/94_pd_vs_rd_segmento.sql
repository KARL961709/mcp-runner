-- 94_pd_vs_rd_segmento.sql | calce de la PD calibrada contra la RD observada, por entidad, bloque y personeria. Solo cosechas con target maduro. EC positivo = el modelo sobre-predice
SELECT entidad,
       CASE WHEN flg_clean = 1 THEN 'clean' ELSE 'dirty' END               AS bloque,
       personeria,
       count(1)                                                            AS n,
       sum(TRY_CAST(target_12m AS INTEGER))                                AS malos,
       round(100.0 * avg(TRY_CAST(target_12m AS DOUBLE)), 3)               AS rd12_pct,
       round(100.0 * avg(prob_modelo_cal), 3)                              AS pd_cal_pct,
       round(100.0 * (avg(prob_modelo_cal)
             / nullif(avg(TRY_CAST(target_12m AS DOUBLE)), 0) - 1), 1)     AS ec_pct,
       round(avg(CAST(puntuacion_modelo AS DOUBLE)), 0)                    AS punt_media,
       sum(CASE WHEN flg_clean_calib = 99 THEN 1 ELSE 0 END)               AS de_bucket_99
FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
WHERE prob_modelo_cal IS NOT NULL
  AND target_12m IS NOT NULL
GROUP BY entidad,
         CASE WHEN flg_clean = 1 THEN 'clean' ELSE 'dirty' END,
         personeria
ORDER BY entidad, bloque, personeria
