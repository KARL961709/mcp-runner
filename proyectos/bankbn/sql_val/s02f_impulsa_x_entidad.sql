-- s02f_impulsa_x_entidad.sql | Impulsa saca 46% de IBK: saca lo mismo de SSFF? si no, las poblaciones comparadas no son comparables
SELECT entidad,
       count(1)                                                              AS base_universo,
       sum(filtro_impulsa_m0)                                                AS n_impulsa_m0,
       round(100.0 * sum(filtro_impulsa_m0) / count(1), 2)                   AS pct_impulsa_m0,
       sum(filtro_impulsa_u12m)                                              AS n_impulsa_u12m,
       round(100.0 * sum(filtro_impulsa_u12m) / count(1), 2)                 AS pct_impulsa_u12m,
       sum(CASE WHEN filtro_impulsa_m0 + filtro_impulsa_u12m > 0 THEN 1 ELSE 0 END) AS n_impulsa_algo,
       round(100.0 * sum(CASE WHEN filtro_impulsa_m0 + filtro_impulsa_u12m > 0 THEN 1 ELSE 0 END) / count(1), 2) AS pct_impulsa_algo,
       sum(filtro_reactiva_puro)                                             AS n_reactiva,
       sum(CASE WHEN flg_clean IN (0,1) THEN 1 ELSE 0 END)                   AS n_sobrevive,
       round(100.0 * sum(CASE WHEN flg_clean IN (0,1) THEN 1 ELSE 0 END) / count(1), 2) AS pct_sobrevive,
       round(100.0 * sum(CASE WHEN filtro_impulsa_m0 + filtro_impulsa_u12m > 0 THEN target_12m ELSE 0 END)
                   / nullif(sum(CASE WHEN filtro_impulsa_m0 + filtro_impulsa_u12m > 0 THEN 1 ELSE 0 END),0), 2) AS badrate_impulsa,
       round(100.0 * sum(CASE WHEN flg_clean IN (0,1) THEN target_12m ELSE 0 END)
                   / nullif(sum(CASE WHEN flg_clean IN (0,1) THEN 1 ELSE 0 END),0), 2) AS badrate_sobrevive
FROM disc_model_owner.ds_adm_bpe_bankbn_cal
WHERE CAST(codmes AS VARCHAR) BETWEEN '202206' AND '202506'
  AND entidad IN ('IBK','BCP','BBVA','SCOTIA')
  AND target_12m IS NOT NULL
GROUP BY entidad
ORDER BY pct_impulsa_algo DESC
