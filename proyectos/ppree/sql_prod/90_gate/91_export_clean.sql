-- ============================================================================
-- 91. PARQUET CLEAN - la poblacion que entra al fit
--   WHERE canonico: flg_scope_ree = 1 AND flg_clean = 1 AND flg_calib = 1
--   Medido: 26,348 filas, 19 cohortes (202312-202506), RD12 = 3.31%
--   Nombres compatibles con el consumidor de Fase 2 (export_master_from_athena
--   .py#L31-41): codmes, tip_doc, key_value, target_1m..12m, pd, score,
--   tipo_ingreso, tipo_ingreso_dep, tipo_ingreso_cs. Los ejes nuevos van al
--   lado, no en lugar de.
--   CTAS exige el external_location VACIO: limpiar antes de re-correr.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_px_clean
WITH (format = 'PARQUET', write_compression = 'SNAPPY',
      external_location = '<S3_DATOS>/clean/') AS
SELECT
  codmes_mrm                AS codmes,
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
  max_dm_12,
  miss_12t,
  valida_colab,
  ctrl_fuente_nueva
FROM disc_model_owner.ds_stk_ree_pp_cal
WHERE flg_scope_ree = 1 AND flg_clean = 1 AND flg_calib = 1
