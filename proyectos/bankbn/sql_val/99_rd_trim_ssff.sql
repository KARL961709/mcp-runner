-- 99_rd_trim_ssff.sql | RD 12m por trimestre y grupo de entidad, sobre el flg_clean BINARIO. Habilita validar la relacion macro-mora fuera del Top-4, donde hay 854k clean contra 9,977 de IBK
SELECT CAST(SUBSTRING(codmes, 1, 4) AS INT) * 10
         + ((CAST(SUBSTRING(codmes, 5, 2) AS INT) - 1) / 3 + 1)                       AS trim,
       sum(CASE WHEN entidad = 'IBK'  THEN 1 ELSE 0 END)                              AS n_ibk,
       round(100.0 * sum(CASE WHEN entidad = 'IBK'  THEN TRY_CAST(target_12m AS DOUBLE) ELSE 0 END)
             / nullif(sum(CASE WHEN entidad = 'IBK'  THEN 1 ELSE 0 END), 0), 4)       AS rd_ibk,
       sum(CASE WHEN entidad IN ('BCP','BBVA','SCOTIA') THEN 1 ELSE 0 END)            AS n_top4r,
       round(100.0 * sum(CASE WHEN entidad IN ('BCP','BBVA','SCOTIA') THEN TRY_CAST(target_12m AS DOUBLE) ELSE 0 END)
             / nullif(sum(CASE WHEN entidad IN ('BCP','BBVA','SCOTIA') THEN 1 ELSE 0 END), 0), 4) AS rd_top4r,
       sum(CASE WHEN entidad = 'OTRO' THEN 1 ELSE 0 END)                              AS n_ssff,
       round(100.0 * sum(CASE WHEN entidad = 'OTRO' THEN TRY_CAST(target_12m AS DOUBLE) ELSE 0 END)
             / nullif(sum(CASE WHEN entidad = 'OTRO' THEN 1 ELSE 0 END), 0), 4)       AS rd_ssff
FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
WHERE target_12m IS NOT NULL
  AND flg_clean = 1
GROUP BY CAST(SUBSTRING(codmes, 1, 4) AS INT) * 10
         + ((CAST(SUBSTRING(codmes, 5, 2) AS INT) - 1) / 3 + 1)
ORDER BY trim
