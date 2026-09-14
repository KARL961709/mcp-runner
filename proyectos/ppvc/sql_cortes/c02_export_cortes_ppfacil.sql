-- c02. Export agregado para optimizar puntos de corte PP Facil (7 grupos): (codmes, punt, n, n_bad) sobre altas IBK clean maduras.
--   Sin key_value (no sale detalle). Se baja con -Bajar. Insumo del optimizador local (min MAE vs apetito + monotonia trimestral + IC Jeffreys).
CREATE TABLE disc_model_owner.tmp_cortes_ppfacil_export
WITH (format = 'PARQUET', parquet_compression = 'SNAPPY', external_location = '<S3_DATOS>/cortes_ppfacil/') AS
SELECT CAST(codmes AS varchar) AS codmes,
  puntuacion_modelo_cal_ppfacil AS punt,
  COUNT(*) AS n,
  SUM(CAST(target_12m AS bigint)) AS n_bad
FROM disc_model_owner.altas_adm_pp_cdpp_cal
WHERE sub_producto = 'PP_FACIL' AND flg_ibk = 1 AND flg_clean = 1
  AND target_12m IS NOT NULL AND puntuacion_modelo_cal_ppfacil IS NOT NULL
GROUP BY CAST(codmes AS varchar), puntuacion_modelo_cal_ppfacil
