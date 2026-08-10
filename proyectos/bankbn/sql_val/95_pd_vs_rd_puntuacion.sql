-- 95_pd_vs_rd_puntuacion.sql | reliability por decil de puntuacion, IBK contra el resto. Si el modelo ordena bien, la RD debe caer de forma monotona al subir la puntuacion
SELECT grupo,
       decil,
       count(1)                                                            AS n,
       min(puntuacion_modelo)                                              AS punt_min,
       max(puntuacion_modelo)                                              AS punt_max,
       sum(TRY_CAST(target_12m AS INTEGER))                                AS malos,
       round(100.0 * avg(TRY_CAST(target_12m AS DOUBLE)), 3)               AS rd12_pct,
       round(100.0 * avg(prob_modelo_cal), 3)                              AS pd_cal_pct,
       round(100.0 * (avg(prob_modelo_cal)
             / nullif(avg(TRY_CAST(target_12m AS DOUBLE)), 0) - 1), 1)     AS ec_pct
FROM (
    SELECT CASE WHEN entidad = 'IBK' THEN 'A_IBK' ELSE 'B_RESTO_TOP4' END AS grupo,
           puntuacion_modelo,
           prob_modelo_cal,
           target_12m,
           NTILE(10) OVER (PARTITION BY CASE WHEN entidad = 'IBK' THEN 'A_IBK' ELSE 'B_RESTO_TOP4' END
                           ORDER BY puntuacion_modelo)                     AS decil
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
    WHERE prob_modelo_cal IS NOT NULL
      AND target_12m IS NOT NULL
) q
GROUP BY grupo, decil
ORDER BY grupo, decil
