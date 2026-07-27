-- ============================================================================
-- 90. PARQUET MASTER - el perimetro reenganche COMPLETO, detalle individual
--   Reemplaza a lo que hoy baja export_master_from_athena.py.
--   WHERE unico: flg_scope_ree = 1. Las 90 cohortes 201901-202606, ~119k filas.
--   La ventana NO es un WHERE: los flags viajan como columnas y Fase 2 recorta.
--     rd_hist  -> codmes <= 202506 AND target_12m IS NOT NULL
--     fit      -> flg_clean = 1 AND flg_calib = 1        (202312-202506)
--     dirty    -> flg_clean = 0
--   Sin este archivo el historico individual no existe: clean arranca en 202312
--   porque flg_calib exige pd, y macro ya viene agregado.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_px_master
WITH (format = 'PARQUET', write_compression = 'SNAPPY',
      external_location = '<S3_DATOS>/master/') AS
SELECT
  codmes_mrm                AS codmes,
  codmes_scr,
  tip_doc,
  id_value                  AS key_value,
  target_01m_60             AS target_1m,
  target_02m_60             AS target_2m,
  target_03m_60             AS target_3m,
  target_04m_60             AS target_4m,
  target_05m_60             AS target_5m,
  target_06m_60             AS target_6m,
  target_07m_60             AS target_7m,
  target_08m_60             AS target_8m,
  target_09m_60             AS target_9m,
  target_10m_60             AS target_10m,
  target_11m_60             AS target_11m,
  target_12m_60             AS target_12m,
  target_09m_30             AS target_9m_30,
  target_12m_30             AS target_12m_30,
  pd_raw                    AS pd,
  score_raw                 AS score,
  tipo_ingreso,
  tipo_ingreso_dep,
  sit_lab_cs_4v             AS tipo_ingreso_cs,
  sit_lab_cs_5v,
  flg_cs_estado,
  flg_cs,
  flg_clean,
  flg_calib,
  filtro_gtia_hip,
  filtro_colab,
  filtro_mto_pend,
  filtro_malo_sf,
  filtro_malo_origen,
  filtro_baja,
  max_dm_12,
  miss_12t,
  falla_madurez_01,
  falla_madurez_03,
  falla_madurez_06,
  falla_madurez_09,
  falla_madurez_12,
  falla_cruce_pd,
  falla_foto_t0,
  falla_dup,
  valida_colab,
  valida_scope,
  ctrl_fuente_nueva
FROM disc_model_owner.ds_stk_ree_pp_cal
WHERE flg_scope_ree = 1
