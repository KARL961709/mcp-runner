-- ============================================================================
-- 90. PARQUET EXPORT del _cal de PP VC - universo de FIT (donde hay pd_raw).
--   La calibracion (isotonica/beta/etc) solo aplica donde EXISTE pd_raw, y el
--   fit es IBK. Por eso el parquet es lo NECESARIO: IBK scoreado, clean+dirty,
--   sin scope-out (99), sin key_value.
--     WHERE: flg_ibk = 1 AND flg_pd_raw = 1 AND flg_clean IN (0,1)
--   ~157k filas (PP_FACIL clean 137k + PP_CD clean 16k + dirty ~3.5k).
--   La ventana NO es un WHERE extra: flg_clean/target viajan como columnas y el
--   pipeline recorta (fit clean=1 maduro, dirty=0 maduro).
--   Las series macro/panel amplias (SS.FF junto/separado 2019+) salen de la
--   inspeccion agregada (i03/i08/i09), NO de este detalle.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_pp_cdpp_px_cal
WITH (format = 'PARQUET', write_compression = 'SNAPPY',
      external_location = '<S3_DATOS>/cal/') AS
SELECT
  codmes,
  cod_instit_financiera,
  flg_ibk,
  sub_producto,
  tipo_ingreso,
  nodo,
  pd_raw,
  flg_pd_raw,
  flg_clean,
  flg_calib,
  target_01m,
  target_02m,
  target_03m,
  target_04m,
  target_05m,
  target_06m,
  target_07m,
  target_08m,
  target_09m,
  target_10m,
  target_11m,
  target_12m
FROM disc_model_owner.ds_adm_pp_cdpp_cal
WHERE flg_ibk = 1
  AND flg_pd_raw = 1
  AND flg_clean IN (0, 1)
