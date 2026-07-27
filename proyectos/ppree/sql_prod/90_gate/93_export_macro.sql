-- ============================================================================
-- 93. PARQUET MACRO - serie de bad-rate honesta, agregada, sin key_value
--   Alimenta la LRA y la seleccion de variables macro, asi que NO exige score:
--   el recorte es flg_clean <> 99 (otra poblacion) + madurez, no flg_calib.
--   Bordes recortados por construccion: solo cohortes con falla_madurez_12 = 0,
--   o sea hasta 202506.
--   Lleva n_meses_fut_faltantes para que las cohortes 202007-202106, que pierden
--   el mes 202107 de su ventana, sean identificables en vez de invisibles.
--   Sin key_value: es una serie, no un detalle.
--   Emite la RD en cuatro cortes para que la seleccion de variable macro pueda
--   probar sensibilidad sin rehacer el parquet: rd12 (clean+dirty, el consumo
--   declarado), rd12_clean, rd12_dirty, y rd12_ventana_completa (excluye las 12
--   cohortes 202007-202106 que pierden el mes 202107 de su ventana futura).
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_px_macro
WITH (format = 'PARQUET', write_compression = 'SNAPPY',
      external_location = '<S3_DATOS>/macro/') AS
SELECT
  codmes_mrm                                                          AS codmes,
  COUNT(*)                                                            AS n,
  SUM(target_12m_60)                                                  AS def12,
  ROUND(AVG(CAST(target_12m_60 AS DOUBLE)), 6)                        AS rd12,
  SUM(target_09m_60)                                                  AS def09,
  ROUND(AVG(CAST(target_09m_60 AS DOUBLE)), 6)                        AS rd09,
  SUM(target_06m_60)                                                  AS def06,
  ROUND(AVG(CAST(target_06m_60 AS DOUBLE)), 6)                        AS rd06,
  SUM(target_12m_30)                                                  AS def12_30,
  ROUND(AVG(CAST(target_12m_30 AS DOUBLE)), 6)                        AS rd12_30,
  SUM(CASE WHEN tipo_ingreso_dep = 'DEP' THEN 1 ELSE 0 END)           AS n_dep,
  ROUND(AVG(CASE WHEN tipo_ingreso_dep = 'DEP'
                 THEN CAST(target_12m_60 AS DOUBLE) END), 6)          AS rd12_dep,
  ROUND(AVG(CASE WHEN tipo_ingreso_dep = 'NO DEP'
                 THEN CAST(target_12m_60 AS DOUBLE) END), 6)          AS rd12_nodep,
  SUM(CASE WHEN flg_clean = 1 THEN 1 ELSE 0 END)                      AS n_clean,
  ROUND(AVG(CASE WHEN flg_clean = 1
                 THEN CAST(target_12m_60 AS DOUBLE) END), 6)          AS rd12_clean,
  SUM(CASE WHEN flg_clean = 0 THEN 1 ELSE 0 END)                      AS n_dirty,
  ROUND(AVG(CASE WHEN flg_clean = 0
                 THEN CAST(target_12m_60 AS DOUBLE) END), 6)          AS rd12_dirty,
  SUM(CASE WHEN miss_12t = 0 THEN 1 ELSE 0 END)                       AS n_ventana_completa,
  ROUND(AVG(CASE WHEN miss_12t = 0
                 THEN CAST(target_12m_60 AS DOUBLE) END), 6)          AS rd12_ventana_completa,
  SUM(CASE WHEN falla_cruce_pd = 0 THEN 1 ELSE 0 END)                 AS n_con_pd,
  MAX(miss_12t)                                                       AS max_meses_fut_faltantes,
  SUM(CASE WHEN miss_12t > 0 THEN 1 ELSE 0 END)                       AS n_ventana_incompleta,
  MAX(falla_foto_t0)                                                  AS flg_mes_sin_foto,
  MAX(valida_colab)                                                   AS flg_colab_vigente
FROM disc_model_owner.ds_stk_ree_pp_cal
WHERE flg_scope_ree = 1
  AND flg_clean <> 99
  AND falla_madurez_12 = 0
GROUP BY codmes_mrm
