-- ============================================================================
-- 90. PARQUET EXPORT del _cal de PP VC - detalle individual SIN key_value.
--   Insumo del fit local (metodologia TC No Bank). WHERE unico: flg_calib = 1
--   (clean + dirty, deja fuera el 99 scope-out). La ventana NO es un WHERE:
--   flg_clean / flg_calib / pd_raw / target viajan como columnas y el pipeline
--   recorta en local:
--     fit      -> flg_ibk = 1 AND flg_clean = 1 AND target_12m IS NOT NULL
--     dirty    -> flg_ibk = 1 AND flg_clean = 0 AND target_12m IS NOT NULL
--     rd_hist  -> target_12m IS NOT NULL   (serie amplia 201901+, macro/panel)
--   Conserva las 5 entidades (cod_instit_financiera) para el panel SS.FF.
--   Sin key_value: no viaja detalle de cliente.
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
WHERE flg_calib = 1
