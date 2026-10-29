-- ============================================================================
-- 96. PARQUET MASTER extendido - perimetro reenganche hasta el ultimo codmes
--   Tabla y location NUEVOS: el CTAS falla si el S3 no esta vacio.
--   Sin id_value ni tip_doc: la calibracion no los usa.
--   scope_source no se proyecta: es funcion de codmes (medido, 0 meses mixtos).
--   La ventana NO es un WHERE - los flags viajan y Fase 2 recorta.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_px_master_2609
WITH (format = 'PARQUET', write_compression = 'SNAPPY',
      external_location = '<S3_DATOS>/master_2609/') AS
SELECT
  codmes_mrm        AS codmes,
  codmes_scr,
  pd_raw            AS pd,
  score_raw         AS score,
  tipo_ingreso,
  tipo_ingreso_dep,
  target_06m_60     AS target_6m,
  target_09m_60     AS target_9m,
  target_12m_60     AS target_12m,
  target_12m_30,
  flg_clean,
  flg_calib,
  falla_madurez_06,
  falla_madurez_09,
  falla_madurez_12,
  falla_cruce_pd,
  valida_scope,
  ctrl_fuente_nueva
FROM disc_model_owner.ds_stk_ree_pp_cal
WHERE flg_scope_ree = 1
