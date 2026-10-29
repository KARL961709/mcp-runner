-- ============================================================================
-- 95. PARQUET MASTER - ANCLA D-1 (contrafactual del desfase de un mes)
--   Misma proyeccion que 90_export_master, 47 columnas en el mismo orden.
--   Lo unico que cambia es QUE FILA se exporta: para cada alta anclada en D
--   se toma la fila del MISMO cliente en D-1, que ya existe en la tabla
--   porque flg_scope_ree es un eje y no un WHERE. Asi pd_raw viene del
--   archivo D, que es el que genero el lead de campana.
--   Ventana cortada en 202604: el parquet vigente tiene 88 cohortes y mover
--   tambien la ventana confunde el efecto del ancla con el de dos meses mas.
--   Correr v18 antes: si n_alta <> n_alta distinct el INNER JOIN hace fan-out.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_px_master_dm1
WITH (format = 'PARQUET', write_compression = 'SNAPPY',
      external_location = '<S3_DATOS>/master_dm1/') AS
WITH alta AS (
  SELECT
    id_value,
    tip_doc,
    DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(codmes_mrm, '%Y%m')), '%Y%m') AS codmes_dm1
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE flg_scope_ree = 1
    AND codmes_mrm <= '202604'
)
SELECT
  c.codmes_mrm                AS codmes,
  c.codmes_scr,
  c.tip_doc,
  c.id_value                  AS key_value,
  c.target_01m_60             AS target_1m,
  c.target_02m_60             AS target_2m,
  c.target_03m_60             AS target_3m,
  c.target_04m_60             AS target_4m,
  c.target_05m_60             AS target_5m,
  c.target_06m_60             AS target_6m,
  c.target_07m_60             AS target_7m,
  c.target_08m_60             AS target_8m,
  c.target_09m_60             AS target_9m,
  c.target_10m_60             AS target_10m,
  c.target_11m_60             AS target_11m,
  c.target_12m_60             AS target_12m,
  c.target_09m_30             AS target_9m_30,
  c.target_12m_30             AS target_12m_30,
  c.pd_raw                    AS pd,
  c.score_raw                 AS score,
  c.tipo_ingreso,
  c.tipo_ingreso_dep,
  c.sit_lab_cs_4v             AS tipo_ingreso_cs,
  c.sit_lab_cs_5v,
  c.flg_cs_estado,
  c.flg_cs,
  c.flg_clean,
  c.flg_calib,
  c.filtro_gtia_hip,
  c.filtro_colab,
  c.filtro_mto_pend,
  c.filtro_malo_sf,
  c.filtro_malo_origen,
  c.filtro_baja,
  c.max_dm_12,
  c.miss_12t,
  c.falla_madurez_01,
  c.falla_madurez_03,
  c.falla_madurez_06,
  c.falla_madurez_09,
  c.falla_madurez_12,
  c.falla_cruce_pd,
  c.falla_foto_t0,
  c.falla_dup,
  c.valida_colab,
  c.valida_scope,
  c.ctrl_fuente_nueva
FROM disc_model_owner.ds_stk_ree_pp_cal c
INNER JOIN alta a
  ON  c.id_value   = a.id_value
  AND c.tip_doc    = a.tip_doc
  AND c.codmes_mrm = a.codmes_dm1
