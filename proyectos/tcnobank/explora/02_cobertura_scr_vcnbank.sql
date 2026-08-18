-- 02. COBERTURA POR MES DE scr_vcnbank_rsk
--   hasta donde llega hacia atras, contando filas. Acota el tamano del build:
--   son ~25M filas por mes, dos ordenes de magnitud mas que las altas
SELECT p_codmes                                                                AS codmes,
       COUNT(*)                                                                AS n_filas,
       COUNT(DISTINCT key_value)                                               AS n_personas,
       SUM(CASE WHEN TRY_CAST(prob_model AS DOUBLE) IS NULL THEN 1 ELSE 0 END) AS n_sin_pd_raw
  FROM e_perm_aws.scr_vcnbank_rsk
 WHERE p_codmes >= '202201'
 GROUP BY p_codmes
 ORDER BY 1
