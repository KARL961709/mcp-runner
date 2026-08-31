-- ============================================================================
-- 90. PARQUET MASTER de PP VC - IBK, ventana AMPLIA (como el master de TCNB).
--   Replica la extraccion de TCNB: IBK, TODOS los meses (201901+), clean+dirty,
--   sin scope-out (99), sin key_value. La ventana NO es un WHERE: flg_clean,
--   pd_raw y los 12 targets viajan como columnas y el pipeline parte:
--     rd_hist / LRA / rho / macro -> 201901+  (usan target, pd puede ser NULL)
--     calibracion (modelo)        -> 202311+  (donde pd_raw NO es NULL)
--     proyecciones                -> target_01m..11m (cohortes inmaduras)
--   OJO: la pd NO existe antes de 202311; por eso NO se filtra por flg_pd_raw
--   aqui (se filtraria adentro para el fit). ~514k filas.
--   Las series SS.FF junto/separado (panel del ciclo) salen de la inspeccion
--   agregada (i08/i09), NO de este detalle (IBK).
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
  AND flg_clean IN (0, 1)
