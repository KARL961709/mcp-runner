-- ============================================================================
-- 93. PARQUET MACRO - serie de bad-rate honesta, agregada, sin key_value
--   Alimenta la LRA y la seleccion de variables macro, asi que NO exige score:
--   el recorte es flg_clean <> 99 (otra poblacion) + madurez, no flg_calib.
--   Bordes recortados por construccion: solo cohortes con falla_madurez_12 = 0,
--   o sea hasta 202506.
--   Sin key_value: es una serie, no un detalle.
--   Emite la RD en cortes para probar sensibilidad sin rehacer el parquet:
--   rd12 (clean+dirty, el consumo declarado), rd12_clean y rd12_dirty.
--
--   CUIDADO con rd12_ventana_completa (miss_12t = 0) — MEDIDO 2026-07-27:
--   miss_12t NO cuenta el hueco 202107. Cuenta, POR CLIENTE, en cuantos de los
--   12 meses futuros no tiene fila en el cierre, y eso es salida de cartera.
--   RD12 por tramo: miss=0 -> 2.85% | 1-2 -> 12.94% | 3-5 -> 18.29% |
--   6-8 -> 10.49% | 9-11 -> 1.30% | 12 -> 0.92%. Son dos poblaciones opuestas:
--   salida tardia y deteriorada (el que cae sale por castigo/refinanciacion) y
--   salida temprana y sana (prepago). Restringir a miss_12t = 0 deja una serie
--   de SOBREVIVIENTES que excluye justo a los que caen: en la ventana del fit
--   tira la RD de 3.31% a 1.48%. NO usarla para elegir la macro ni como
--   sensibilidad de RD (ACUERDOS H112, A49).
--   Las cohortes 202007-202106 sí traen miss>0 en el 100% de sus filas por el
--   hueco 202107, pero el resto de meses tambien trae 25-38% por salida, asi
--   que la columna no aisla el hueco.
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
