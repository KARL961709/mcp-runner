-- ============================================================================
-- F1. COBERTURA DE LA MADRE DE PRODUCCION e_perm_aws.ds_flg_compppibk_rsk
--     (la enr_ copia devolvio n=0). Serie contando FILAS por codmes_mrm.
-- ============================================================================
SELECT
  codmes_mrm,
  COUNT(*)                                                                     AS n,
  COUNT(DISTINCT CAST(tip_doc AS VARCHAR) || '|' || CAST(id_value AS VARCHAR))  AS n_llaves,
  SUM(CASE WHEN nro_dm_m01 IS NULL THEN 1 ELSE 0 END)                          AS n_sin_m01,
  SUM(CASE WHEN nro_dm_m12 IS NULL THEN 1 ELSE 0 END)                          AS n_sin_m12,
  ROUND(AVG(CAST(
      (CASE WHEN nro_dm_m01 IS NULL THEN 0 ELSE 1 END)
    + (CASE WHEN nro_dm_m02 IS NULL THEN 0 ELSE 1 END)
    + (CASE WHEN nro_dm_m03 IS NULL THEN 0 ELSE 1 END)
    + (CASE WHEN nro_dm_m04 IS NULL THEN 0 ELSE 1 END)
    + (CASE WHEN nro_dm_m05 IS NULL THEN 0 ELSE 1 END)
    + (CASE WHEN nro_dm_m06 IS NULL THEN 0 ELSE 1 END)
    + (CASE WHEN nro_dm_m07 IS NULL THEN 0 ELSE 1 END)
    + (CASE WHEN nro_dm_m08 IS NULL THEN 0 ELSE 1 END)
    + (CASE WHEN nro_dm_m09 IS NULL THEN 0 ELSE 1 END)
    + (CASE WHEN nro_dm_m10 IS NULL THEN 0 ELSE 1 END)
    + (CASE WHEN nro_dm_m11 IS NULL THEN 0 ELSE 1 END)
    + (CASE WHEN nro_dm_m12 IS NULL THEN 0 ELSE 1 END) AS DOUBLE)), 3)          AS prom_meses_fut_obs,
  SUM(CASE WHEN dsc_flg_malo_12m = 'MALO' THEN 1 ELSE 0 END)                    AS n_malo_12m,
  MIN(LENGTH(CAST(id_value AS VARCHAR)))                                        AS len_min_key,
  MAX(LENGTH(CAST(id_value AS VARCHAR)))                                        AS len_max_key
FROM e_perm_aws.ds_flg_compppibk_rsk
GROUP BY 1
ORDER BY 1
