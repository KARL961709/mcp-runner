-- ============================================================================
-- E0b. DOMINIO LITERAL DE LA CASCADA (los 10 valores, byte a byte)
-- ============================================================================
SELECT
  dsc_flg_malo_12m                                          AS valor,
  LENGTH(dsc_flg_malo_12m)                                  AS n_chars,
  LENGTH(TO_UTF8(dsc_flg_malo_12m))                         AS n_bytes,
  COUNT(*)                                                  AS n,
  COUNT(DISTINCT codmes_mrm)                                AS n_meses,
  MIN(codmes_mrm)                                           AS mes_min,
  MAX(codmes_mrm)                                           AS mes_max
FROM disc_model_owner.enr_ds_flg_compppibk_rsk
GROUP BY 1, 2, 3
ORDER BY 4 DESC
