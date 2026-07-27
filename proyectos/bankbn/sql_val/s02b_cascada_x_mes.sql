-- s02b_cascada_x_mes.sql | los 3 meses del slide abiertos: valida que el promedio no esconda un mes anomalo
SELECT CAST(codmes AS VARCHAR)                                                       AS codmes,
       count(1)                                                                      AS n_total,
       sum(CASE WHEN flg_clean = 0 THEN 1 ELSE 0 END)                                AS n_dirty,
       sum(CASE WHEN flg_clean = 1 AND entidad IN ('BCP','BBVA','SCOTIA') THEN 1 ELSE 0 END) AS n_grupo_a,
       sum(CASE WHEN flg_clean = 1 AND entidad = 'IBK' THEN 1 ELSE 0 END)            AS n_grupo_b,
       sum(CASE WHEN flg_clean = 1 AND entidad = 'IBK' AND COALESCE(flg_ppjj,0) = 0 THEN 1 ELSE 0 END) AS n_ppnn,
       sum(CASE WHEN flg_clean = 1 AND entidad = 'IBK' AND COALESCE(flg_ppjj,0) = 1 THEN 1 ELSE 0 END) AS n_ppjj,
       round(100.0 * sum(target_12m) / count(1), 2)                                  AS tasa_total,
       round(100.0 * sum(CASE WHEN flg_clean = 1 AND entidad IN ('BCP','BBVA','SCOTIA') THEN target_12m ELSE 0 END)
                   / nullif(sum(CASE WHEN flg_clean = 1 AND entidad IN ('BCP','BBVA','SCOTIA') THEN 1 ELSE 0 END),0), 2) AS tasa_grupo_a,
       round(100.0 * sum(CASE WHEN flg_clean = 1 AND entidad = 'IBK' THEN target_12m ELSE 0 END)
                   / nullif(sum(CASE WHEN flg_clean = 1 AND entidad = 'IBK' THEN 1 ELSE 0 END),0), 2) AS tasa_grupo_b,
       round(100.0 * sum(CASE WHEN flg_clean = 1 AND entidad = 'IBK' AND COALESCE(flg_ppjj,0) = 0 THEN target_12m ELSE 0 END)
                   / nullif(sum(CASE WHEN flg_clean = 1 AND entidad = 'IBK' AND COALESCE(flg_ppjj,0) = 0 THEN 1 ELSE 0 END),0), 2) AS tasa_ppnn,
       round(100.0 * sum(CASE WHEN flg_clean = 1 AND entidad = 'IBK' AND COALESCE(flg_ppjj,0) = 1 THEN target_12m ELSE 0 END)
                   / nullif(sum(CASE WHEN flg_clean = 1 AND entidad = 'IBK' AND COALESCE(flg_ppjj,0) = 1 THEN 1 ELSE 0 END),0), 2) AS tasa_ppjj
FROM disc_model_owner.ds_adm_bpe_bankbn_cal
WHERE CAST(codmes AS VARCHAR) IN ('202504','202505','202506')
  AND flg_clean IN (0, 1)
  AND target_12m IS NOT NULL
GROUP BY CAST(codmes AS VARCHAR)
ORDER BY codmes
