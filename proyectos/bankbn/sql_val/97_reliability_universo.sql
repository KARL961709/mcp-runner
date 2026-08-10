-- 97_reliability_universo.sql | reliability por decil de puntuacion dentro de IBK, separando el universo de ajuste del bucket 99. Si el EC del ajuste es plano y cercano a cero, la calibracion esta sana y el desvio viene del 99
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
    SELECT CASE WHEN flg_clean_calib = 99 THEN 'B_bucket99' ELSE 'A_ajuste' END AS grupo,
           puntuacion_modelo, prob_modelo_cal, target_12m,
           NTILE(10) OVER (PARTITION BY CASE WHEN flg_clean_calib = 99 THEN 'B_bucket99' ELSE 'A_ajuste' END
                           ORDER BY puntuacion_modelo)                     AS decil
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
    WHERE prob_modelo_cal IS NOT NULL
      AND target_12m IS NOT NULL
      AND entidad = 'IBK'
) q
GROUP BY grupo, decil
ORDER BY grupo, decil
