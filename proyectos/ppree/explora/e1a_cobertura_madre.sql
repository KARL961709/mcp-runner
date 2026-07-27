-- ============================================================================
-- E1a. COBERTURA DE LA MADRE POR codmes_mrm  (U9 poblado / U4 madurez)
--      Serie contando FILAS. Ninguna evidencia de particiones declaradas.
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
  SUM(CASE WHEN score IS NULL OR score = 0 THEN 1 ELSE 0 END)                   AS n_sin_score,
  MAX("$file_modified_time" AT TIME ZONE 'America/Lima')                        AS max_fch_archivo
FROM disc_model_owner.enr_ds_flg_compppibk_rsk
GROUP BY 1
ORDER BY 1
