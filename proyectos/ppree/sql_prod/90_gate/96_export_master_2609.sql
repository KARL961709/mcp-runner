-- ============================================================================
-- 96. PARQUET MASTER extendido - ancla codmes_mrm, SIN corte de madurez
--
--   ANCLA: esta calibracion es codmes_mrm. No se elige aca: se hereda de
--   ds_stk_ree_pp_cal, que v30 probo anclada en codmes_mrm contra
--   scr_stk_ree_pp_cal_2023_202610 (49,430 de 49,430 identicas, y 0 por
--   codmes_scr). codmes_scr viaja solo para poder verificarlo, no es el mes
--   de la pd.
--
--   El master anterior traia falla_madurez_12 = 1 en CERO filas: se exporto
--   solo lo maduro y por eso terminaba en 202509. Aca viajan los inmaduros y
--   Fase 2 recorta. Los targets cortos entran COMPLETOS porque con el ancla
--   nueva maduran mas lejos que el de 12m y dan senal temprana del tramo nuevo.
--
--   Perimetro como EJES: viajan flg_scope_ree y flg_ree_v4, no una definicion
--   hardcodeada. scope_source no se proyecta: es funcion de codmes (medido, 0
--   meses mixtos). codmes_mrm es string (v19): nunca comparar contra enteros.
--
--   falla_sin_tipo_ingreso y falla_sin_cta_sueldo son OBLIGATORIAS: el segmento
--   es la celda de calibracion, y sin ellas un NO DEP medido no se distingue de
--   uno que cayo ahi por el COALESCE de 40_drivers. Para flg_cs el 54.6 pct de
--   los ceros es por AUSENCIA (cabecera de 40_drivers, A42).
--
--   CRITERIOS DE ACEPTACION del parquet, verificables sin volver a Athena:
--     1  cohorte 202212 con pd NO NULA = 0 filas, y falla_cruce_pd = 1 en ellas
--        (la fuente arranca en 202301, asi que bajo codmes_mrm 202212 no cruza)
--     2  cohorte 202301 con pd no nula > 0
--     3  falla_madurez_12 = 1 en MAS DE 0 filas, y cohortes mas alla de 202509
--     4  filas totales entre 106k y 125k
--   Si 1 falla, el export salio con el ancla vieja. Si 3 falla, el corte de
--   madurez sigue puesto y no sirve.
--
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
  target_01m_60     AS target_1m,
  target_02m_60     AS target_2m,
  target_03m_60     AS target_3m,
  target_04m_60     AS target_4m,
  target_05m_60     AS target_5m,
  target_06m_60     AS target_6m,
  target_07m_60     AS target_7m,
  target_08m_60     AS target_8m,
  target_09m_60     AS target_9m,
  target_10m_60     AS target_10m,
  target_11m_60     AS target_11m,
  target_12m_60     AS target_12m,
  target_09m_30,
  target_12m_30,
  max_dm_06,
  max_dm_12,
  miss_06,
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
  falla_madurez_01,
  falla_madurez_03,
  falla_madurez_06,
  falla_madurez_09,
  falla_madurez_12,
  falla_cruce_pd,
  falla_pd_rango,
  falla_sin_target,
  falla_sin_tipo_ingreso,
  falla_sin_cta_sueldo,
  falla_scope_vs_v4,
  falla_foto_t0,
  falla_dup,
  valida_colab,
  valida_scope,
  ctrl_fuente_nueva,
  ctrl_asof_igual_codmes,
  ctrl_n_cuentas
FROM disc_model_owner.ds_stk_ree_pp_cal
WHERE flg_scope_ree = 1
   OR flg_ree_v4 = 1
