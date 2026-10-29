-- ============================================================================
-- 96. PARQUET MASTER extendido - SIN el corte de madurez
--   El master vigente trae falla_madurez_12 = 1 en CERO filas: se exporto solo
--   lo maduro, y por eso termina en 202509. La pd existe mucho mas alla (v12:
--   reen 202605, stock 202607, scr_stk_ree_pp_cal_2023 202610). Aca viajan los
--   inmaduros con target_12m nulo y falla_madurez_12 = 1, y Fase 2 recorta.
--   Perimetro como EJES: viajan flg_scope_ree y flg_ree_v4, no una definicion
--   hardcodeada, asi las dos variantes se reproducen sin volver a Athena.
--   codmes_mrm es string (v19): nunca comparar contra enteros sin CAST.
--   Tabla y location NUEVOS: el CTAS falla si el S3 no esta vacio.
--   Sin id_value ni tip_doc: la calibracion no los usa.
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
  sit_lab_cs_4v     AS tipo_ingreso_cs,
  sit_lab_cs_5v,
  flg_cs,
  flg_cs_estado,
  target_03m_60     AS target_3m,
  target_06m_60     AS target_6m,
  target_09m_60     AS target_9m,
  target_12m_60     AS target_12m,
  target_09m_30     AS target_9m_30,
  target_12m_30,
  max_dm_12,
  miss_12t,
  flg_clean,
  flg_calib,
  flg_scope_ree,
  flg_ree_v4,
  filtro_gtia_hip,
  filtro_colab,
  filtro_mto_pend,
  filtro_malo_sf,
  filtro_malo_origen,
  filtro_baja,
  falla_madurez_03,
  falla_madurez_06,
  falla_madurez_09,
  falla_madurez_12,
  falla_cruce_pd,
  falla_pd_rango,
  falla_sin_target,
  falla_scope_vs_v4,
  falla_foto_t0,
  falla_dup,
  valida_colab,
  valida_scope,
  ctrl_fuente_nueva
FROM disc_model_owner.ds_stk_ree_pp_cal
WHERE flg_scope_ree = 1
   OR flg_ree_v4 = 1
