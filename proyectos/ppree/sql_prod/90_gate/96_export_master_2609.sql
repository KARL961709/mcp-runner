-- ============================================================================
-- 96. PARQUET MASTER extendido - DOS pd lado a lado, SIN corte de madurez
--
--   ANCLA: ya no se hereda a ciegas. v33 probo que el parquet de reenganche new
--   lleva el ancla VIEJA (empata la fuente en codmes_scr = M+1 en las siete
--   cohortes de control), aunque el 50_pd del zip tenga el arreglo. Asi que
--   aca viajan las DOS y Fase 2 elige con el dato en la mano:
--     pd      = pd_raw tal como quedo en la tabla gobernada
--     pd_mrm  = la fuente leida EXPLICITAMENTE en cod_mes = codmes_mrm
--   Si las dos coinciden fila a fila, la tabla viva ya estaba bien y pd_mrm es
--   redundante. Si no, pd_mrm es la correcta y el diff queda medible offline
--   para siempre, sin volver a Athena. Que ancla tiene la tabla viva lo mide
--   v34 mes por mes.
--
--   La fuente se DEDUPLICA por llave antes del join (MAX sobre una llave que
--   v24 midio unica, asi que es guarda y no politica): un LEFT JOIN contra una
--   tabla deduplicada no puede inflar filas.
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
--     1  cohorte 202212 con pd_mrm NO NULA = 0 filas (la fuente arranca en
--        202301, asi que bajo codmes_mrm esa cohorte no puede cruzar)
--     2  cohorte 202301 con pd_mrm no nula > 0
--     3  falla_madurez_12 = 1 en MAS DE 0 filas, y cohortes mas alla de 202509
--     4  filas totales entre 106k y 125k
--   Si 1 falla, el join quedo mal armado. Si 3 falla, el corte de madurez sigue
--   puesto y el parquet no sirve para el tramo nuevo.
--
--   Tabla y location NUEVOS: el CTAS falla si el S3 no esta vacio. Si vuelve
--   TIMEOUT, revisar si la tabla quedo creada ANTES de relanzar: el timeout es
--   del runner y no cancela la query en Athena.
--   Sin id_value ni tip_doc: la calibracion no los usa, solo cruzan adentro.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_px_master_2609
WITH (format = 'PARQUET', write_compression = 'SNAPPY',
      external_location = '<S3_DATOS>/master_2609/') AS
SELECT
  t.codmes_mrm        AS codmes,
  t.codmes_scr,
  t.pd_raw            AS pd,
  s.pd                AS pd_mrm,
  t.score_raw         AS score,
  t.tipo_ingreso,
  t.tipo_ingreso_dep,
  t.sit_lab_cs_4v     AS tipo_ingreso_cs,
  t.sit_lab_cs_5v,
  t.flg_cs,
  t.flg_cs_estado,
  t.target_01m_60     AS target_1m,
  t.target_02m_60     AS target_2m,
  t.target_03m_60     AS target_3m,
  t.target_04m_60     AS target_4m,
  t.target_05m_60     AS target_5m,
  t.target_06m_60     AS target_6m,
  t.target_07m_60     AS target_7m,
  t.target_08m_60     AS target_8m,
  t.target_09m_60     AS target_9m,
  t.target_10m_60     AS target_10m,
  t.target_11m_60     AS target_11m,
  t.target_12m_60     AS target_12m,
  t.target_09m_30,
  t.target_12m_30,
  t.max_dm_06,
  t.max_dm_12,
  t.miss_06,
  t.miss_12t,
  t.flg_clean,
  t.flg_calib,
  t.flg_scope_ree,
  t.flg_ree_v4,
  t.filtro_gtia_hip,
  t.filtro_colab,
  t.filtro_mto_pend,
  t.filtro_malo_sf,
  t.filtro_malo_origen,
  t.filtro_baja,
  t.falla_madurez_01,
  t.falla_madurez_03,
  t.falla_madurez_06,
  t.falla_madurez_09,
  t.falla_madurez_12,
  t.falla_cruce_pd,
  t.falla_pd_rango,
  t.falla_sin_target,
  t.falla_sin_tipo_ingreso,
  t.falla_sin_cta_sueldo,
  t.falla_scope_vs_v4,
  t.falla_foto_t0,
  t.falla_dup,
  t.valida_colab,
  t.valida_scope,
  t.ctrl_fuente_nueva,
  t.ctrl_asof_igual_codmes,
  t.ctrl_n_cuentas
FROM disc_model_owner.ds_stk_ree_pp_cal t
LEFT JOIN (
  SELECT CAST(cod_mes AS VARCHAR)         AS mes,
         CAST(cod_tip_doc AS VARCHAR)     AS tip_doc,
         CAST(key_value AS VARCHAR)       AS id_value,
         MAX(CAST(prob_modelo AS DOUBLE)) AS pd
  FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610
  WHERE prob_modelo IS NOT NULL
  GROUP BY 1, 2, 3
) s
  ON  s.mes      = CAST(t.codmes_mrm AS VARCHAR)
  AND s.tip_doc  = CAST(t.tip_doc AS VARCHAR)
  AND s.id_value = CAST(t.id_value AS VARCHAR)
WHERE t.flg_scope_ree = 1
   OR t.flg_ree_v4 = 1
