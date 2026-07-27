-- u3_dirty_lente_asimetrico.sql | la inversion dirty<clean en IBK es muestra chica o el lente asimetrico? ventana completa 202206-202506
SELECT CASE WHEN entidad = 'IBK' THEN '1_IBK' ELSE '2_SSFF' END        AS grupo,
       CASE WHEN flg_clean = 1 THEN 'clean' ELSE 'dirty' END           AS bucket,
       CASE WHEN COALESCE(flg_ppjj,0) = 1 THEN 'PPJJ' ELSE 'PPNN' END  AS personeria,
       count(1)                                                        AS n,
       sum(target_12m)                                                 AS malos,
       round(100.0 * sum(target_12m) / count(1), 2)                    AS tasa_pct,
       round(100.0 * count(1)
             / sum(count(1)) OVER (PARTITION BY CASE WHEN entidad = 'IBK' THEN '1_IBK' ELSE '2_SSFF' END,
                                                CASE WHEN flg_clean = 1 THEN 'clean' ELSE 'dirty' END), 1) AS pct_mix_en_bucket
FROM disc_model_owner.ds_adm_bpe_bankbn_cal
WHERE CAST(codmes AS VARCHAR) BETWEEN '202206' AND '202506'
  AND flg_clean IN (0, 1)
  AND target_12m IS NOT NULL
GROUP BY CASE WHEN entidad = 'IBK' THEN '1_IBK' ELSE '2_SSFF' END,
         CASE WHEN flg_clean = 1 THEN 'clean' ELSE 'dirty' END,
         CASE WHEN COALESCE(flg_ppjj,0) = 1 THEN 'PPJJ' ELSE 'PPNN' END
ORDER BY grupo, bucket, personeria
