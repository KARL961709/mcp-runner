-- ============================================================================
-- 92. PARQUET DIRTY - misma poblacion, condicion que sesga el fit
--   flg_clean = 0: pasa el scope pero falla una honesta (malo_sf o malo_origen).
--   NO es el complemento del clean: el 99 es otra poblacion y no entra aca.
--   Lleva los dos filtros que lo mandaron a dirty, para poder analizar por cual.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_px_dirty
WITH (format = 'PARQUET', write_compression = 'SNAPPY',
      external_location = '<S3_DATOS>/dirty/') AS
SELECT
  codmes_mrm                AS codmes,
  tip_doc,
  id_value                  AS key_value,
  target_01m_60             AS target_1m,
  target_03m_60             AS target_3m,
  target_06m_60             AS target_6m,
  target_09m_60             AS target_9m,
  target_12m_60             AS target_12m,
  target_12m_30,
  pd_raw                    AS pd,
  score_raw                 AS score,
  tipo_ingreso_dep,
  sit_lab_cs_4v             AS tipo_ingreso_cs,
  flg_cs_estado,
  filtro_malo_sf,
  filtro_malo_origen,
  max_dm_12,
  miss_12t,
  falla_madurez_12,
  falla_cruce_pd
FROM disc_model_owner.ds_stk_ree_pp_cal
WHERE flg_scope_ree = 1 AND flg_clean = 0
