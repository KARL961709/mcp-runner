-- ============================================================================
-- 35. TARGET - los 12 horizontes rederivados desde columnas base
--   Combina 30_fut_a (k=1..6) y 30_fut_b (k=7..12). Nunca lee dsc_flg_malo_Nm:
--   la cascada devuelve 'MALO' -> 0, no NULL, para las seis ramas duras (A4).
--   MALO_Nm = mora > umbral EN ALGUN mes de [t0+1, t0+N]  OR  refi  OR  castigo
--   Madurez POR CALENDARIO, nunca resta entera sobre YYYYMM (O6).
--   Inmaduro -> NULL, jamas 0.
--   Se exportan los DOCE max_dm y los DOCE falla_madurez (G3): antes salian 5 de
--   12 mientras se emitian 24 targets, asi que siete horizontes quedaban sin eje
--   de madurez ni columna auditable.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_35_target AS
WITH f AS (
  SELECT
    a.codmes_mrm, a.tip_doc, a.id_value,
    a.dm_m1, a.dm_m2, a.dm_m3, a.dm_m4, a.dm_m5, a.dm_m6,
    b.dm_m7, b.dm_m8, b.dm_m9, b.dm_m10, b.dm_m11, b.dm_m12,
    a.miss_m1 + a.miss_m2 + a.miss_m3 + a.miss_m4 + a.miss_m5 + a.miss_m6            AS miss_06,
    b.miss_m7 + b.miss_m8 + b.miss_m9 + b.miss_m10 + b.miss_m11 + b.miss_m12         AS miss_12,
    a.ev_m1, a.ev_m2, a.ev_m3, a.ev_m4, a.ev_m5, a.ev_m6,
    b.ev_m7, b.ev_m8, b.ev_m9, b.ev_m10, b.ev_m11, b.ev_m12
  FROM disc_model_owner.ds_stk_ree_pp_30_fut_a a
  LEFT JOIN disc_model_owner.ds_stk_ree_pp_30_fut_b b
         ON b.codmes_mrm = a.codmes_mrm AND b.tip_doc = a.tip_doc AND b.id_value = a.id_value
),
acc AS (
  SELECT f.*,
    COALESCE(dm_m1,0)                                                                                                        AS max_dm_01,
    GREATEST(COALESCE(dm_m1,0), COALESCE(dm_m2,0))                                                                           AS max_dm_02,
    GREATEST(COALESCE(dm_m1,0), COALESCE(dm_m2,0), COALESCE(dm_m3,0))                                                        AS max_dm_03,
    GREATEST(COALESCE(dm_m1,0), COALESCE(dm_m2,0), COALESCE(dm_m3,0), COALESCE(dm_m4,0))                                     AS max_dm_04,
    GREATEST(COALESCE(dm_m1,0), COALESCE(dm_m2,0), COALESCE(dm_m3,0), COALESCE(dm_m4,0), COALESCE(dm_m5,0))                  AS max_dm_05,
    GREATEST(COALESCE(dm_m1,0), COALESCE(dm_m2,0), COALESCE(dm_m3,0), COALESCE(dm_m4,0), COALESCE(dm_m5,0), COALESCE(dm_m6,0)) AS max_dm_06,
    GREATEST(COALESCE(dm_m1,0), COALESCE(dm_m2,0), COALESCE(dm_m3,0), COALESCE(dm_m4,0), COALESCE(dm_m5,0), COALESCE(dm_m6,0),
             COALESCE(dm_m7,0))                                                                                              AS max_dm_07,
    GREATEST(COALESCE(dm_m1,0), COALESCE(dm_m2,0), COALESCE(dm_m3,0), COALESCE(dm_m4,0), COALESCE(dm_m5,0), COALESCE(dm_m6,0),
             COALESCE(dm_m7,0), COALESCE(dm_m8,0))                                                                           AS max_dm_08,
    GREATEST(COALESCE(dm_m1,0), COALESCE(dm_m2,0), COALESCE(dm_m3,0), COALESCE(dm_m4,0), COALESCE(dm_m5,0), COALESCE(dm_m6,0),
             COALESCE(dm_m7,0), COALESCE(dm_m8,0), COALESCE(dm_m9,0))                                                        AS max_dm_09,
    GREATEST(COALESCE(dm_m1,0), COALESCE(dm_m2,0), COALESCE(dm_m3,0), COALESCE(dm_m4,0), COALESCE(dm_m5,0), COALESCE(dm_m6,0),
             COALESCE(dm_m7,0), COALESCE(dm_m8,0), COALESCE(dm_m9,0), COALESCE(dm_m10,0))                                    AS max_dm_10,
    GREATEST(COALESCE(dm_m1,0), COALESCE(dm_m2,0), COALESCE(dm_m3,0), COALESCE(dm_m4,0), COALESCE(dm_m5,0), COALESCE(dm_m6,0),
             COALESCE(dm_m7,0), COALESCE(dm_m8,0), COALESCE(dm_m9,0), COALESCE(dm_m10,0), COALESCE(dm_m11,0))                AS max_dm_11,
    GREATEST(COALESCE(dm_m1,0), COALESCE(dm_m2,0), COALESCE(dm_m3,0), COALESCE(dm_m4,0), COALESCE(dm_m5,0), COALESCE(dm_m6,0),
             COALESCE(dm_m7,0), COALESCE(dm_m8,0), COALESCE(dm_m9,0), COALESCE(dm_m10,0), COALESCE(dm_m11,0), COALESCE(dm_m12,0)) AS max_dm_12,
    COALESCE(ev_m1,0)                                                                                                        AS ev_01,
    GREATEST(COALESCE(ev_m1,0), COALESCE(ev_m2,0))                                                                           AS ev_02,
    GREATEST(COALESCE(ev_m1,0), COALESCE(ev_m2,0), COALESCE(ev_m3,0))                                                        AS ev_03,
    GREATEST(COALESCE(ev_m1,0), COALESCE(ev_m2,0), COALESCE(ev_m3,0), COALESCE(ev_m4,0))                                     AS ev_04,
    GREATEST(COALESCE(ev_m1,0), COALESCE(ev_m2,0), COALESCE(ev_m3,0), COALESCE(ev_m4,0), COALESCE(ev_m5,0))                  AS ev_05,
    GREATEST(COALESCE(ev_m1,0), COALESCE(ev_m2,0), COALESCE(ev_m3,0), COALESCE(ev_m4,0), COALESCE(ev_m5,0), COALESCE(ev_m6,0)) AS ev_06,
    GREATEST(COALESCE(ev_m1,0), COALESCE(ev_m2,0), COALESCE(ev_m3,0), COALESCE(ev_m4,0), COALESCE(ev_m5,0), COALESCE(ev_m6,0),
             COALESCE(ev_m7,0))                                                                                              AS ev_07,
    GREATEST(COALESCE(ev_m1,0), COALESCE(ev_m2,0), COALESCE(ev_m3,0), COALESCE(ev_m4,0), COALESCE(ev_m5,0), COALESCE(ev_m6,0),
             COALESCE(ev_m7,0), COALESCE(ev_m8,0))                                                                           AS ev_08,
    GREATEST(COALESCE(ev_m1,0), COALESCE(ev_m2,0), COALESCE(ev_m3,0), COALESCE(ev_m4,0), COALESCE(ev_m5,0), COALESCE(ev_m6,0),
             COALESCE(ev_m7,0), COALESCE(ev_m8,0), COALESCE(ev_m9,0))                                                        AS ev_09,
    GREATEST(COALESCE(ev_m1,0), COALESCE(ev_m2,0), COALESCE(ev_m3,0), COALESCE(ev_m4,0), COALESCE(ev_m5,0), COALESCE(ev_m6,0),
             COALESCE(ev_m7,0), COALESCE(ev_m8,0), COALESCE(ev_m9,0), COALESCE(ev_m10,0))                                    AS ev_10,
    GREATEST(COALESCE(ev_m1,0), COALESCE(ev_m2,0), COALESCE(ev_m3,0), COALESCE(ev_m4,0), COALESCE(ev_m5,0), COALESCE(ev_m6,0),
             COALESCE(ev_m7,0), COALESCE(ev_m8,0), COALESCE(ev_m9,0), COALESCE(ev_m10,0), COALESCE(ev_m11,0))                AS ev_11,
    GREATEST(COALESCE(ev_m1,0), COALESCE(ev_m2,0), COALESCE(ev_m3,0), COALESCE(ev_m4,0), COALESCE(ev_m5,0), COALESCE(ev_m6,0),
             COALESCE(ev_m7,0), COALESCE(ev_m8,0), COALESCE(ev_m9,0), COALESCE(ev_m10,0), COALESCE(ev_m11,0), COALESCE(ev_m12,0)) AS ev_12
  FROM f
),
mad AS (
  SELECT acc.*,
    CASE WHEN DATE_FORMAT(DATE_ADD('month',  1, DATE_PARSE(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN 1 ELSE 0 END AS falla_madurez_01,
    CASE WHEN DATE_FORMAT(DATE_ADD('month',  2, DATE_PARSE(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN 1 ELSE 0 END AS falla_madurez_02,
    CASE WHEN DATE_FORMAT(DATE_ADD('month',  3, DATE_PARSE(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN 1 ELSE 0 END AS falla_madurez_03,
    CASE WHEN DATE_FORMAT(DATE_ADD('month',  4, DATE_PARSE(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN 1 ELSE 0 END AS falla_madurez_04,
    CASE WHEN DATE_FORMAT(DATE_ADD('month',  5, DATE_PARSE(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN 1 ELSE 0 END AS falla_madurez_05,
    CASE WHEN DATE_FORMAT(DATE_ADD('month',  6, DATE_PARSE(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN 1 ELSE 0 END AS falla_madurez_06,
    CASE WHEN DATE_FORMAT(DATE_ADD('month',  7, DATE_PARSE(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN 1 ELSE 0 END AS falla_madurez_07,
    CASE WHEN DATE_FORMAT(DATE_ADD('month',  8, DATE_PARSE(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN 1 ELSE 0 END AS falla_madurez_08,
    CASE WHEN DATE_FORMAT(DATE_ADD('month',  9, DATE_PARSE(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN 1 ELSE 0 END AS falla_madurez_09,
    CASE WHEN DATE_FORMAT(DATE_ADD('month', 10, DATE_PARSE(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN 1 ELSE 0 END AS falla_madurez_10,
    CASE WHEN DATE_FORMAT(DATE_ADD('month', 11, DATE_PARSE(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN 1 ELSE 0 END AS falla_madurez_11,
    CASE WHEN DATE_FORMAT(DATE_ADD('month', 12, DATE_PARSE(codmes_mrm, '%Y%m')), '%Y%m') > '202606' THEN 1 ELSE 0 END AS falla_madurez_12
  FROM acc
)
SELECT
  codmes_mrm, tip_doc, id_value,
  max_dm_01, max_dm_02, max_dm_03, max_dm_04, max_dm_05, max_dm_06,
  max_dm_07, max_dm_08, max_dm_09, max_dm_10, max_dm_11, max_dm_12,
  miss_06, miss_06 + miss_12 AS miss_12t,
  falla_madurez_01, falla_madurez_02, falla_madurez_03, falla_madurez_04,
  falla_madurez_05, falla_madurez_06, falla_madurez_07, falla_madurez_08,
  falla_madurez_09, falla_madurez_10, falla_madurez_11, falla_madurez_12,
  CASE WHEN falla_madurez_01 = 1 THEN NULL WHEN max_dm_01 > 60 OR ev_01 = 1 THEN 1 ELSE 0 END AS target_01m_60,
  CASE WHEN falla_madurez_02 = 1 THEN NULL WHEN max_dm_02 > 60 OR ev_02 = 1 THEN 1 ELSE 0 END AS target_02m_60,
  CASE WHEN falla_madurez_03 = 1 THEN NULL WHEN max_dm_03 > 60 OR ev_03 = 1 THEN 1 ELSE 0 END AS target_03m_60,
  CASE WHEN falla_madurez_04 = 1 THEN NULL WHEN max_dm_04 > 60 OR ev_04 = 1 THEN 1 ELSE 0 END AS target_04m_60,
  CASE WHEN falla_madurez_05 = 1 THEN NULL WHEN max_dm_05 > 60 OR ev_05 = 1 THEN 1 ELSE 0 END AS target_05m_60,
  CASE WHEN falla_madurez_06 = 1 THEN NULL WHEN max_dm_06 > 60 OR ev_06 = 1 THEN 1 ELSE 0 END AS target_06m_60,
  CASE WHEN falla_madurez_07 = 1 THEN NULL WHEN max_dm_07 > 60 OR ev_07 = 1 THEN 1 ELSE 0 END AS target_07m_60,
  CASE WHEN falla_madurez_08 = 1 THEN NULL WHEN max_dm_08 > 60 OR ev_08 = 1 THEN 1 ELSE 0 END AS target_08m_60,
  CASE WHEN falla_madurez_09 = 1 THEN NULL WHEN max_dm_09 > 60 OR ev_09 = 1 THEN 1 ELSE 0 END AS target_09m_60,
  CASE WHEN falla_madurez_10 = 1 THEN NULL WHEN max_dm_10 > 60 OR ev_10 = 1 THEN 1 ELSE 0 END AS target_10m_60,
  CASE WHEN falla_madurez_11 = 1 THEN NULL WHEN max_dm_11 > 60 OR ev_11 = 1 THEN 1 ELSE 0 END AS target_11m_60,
  CASE WHEN falla_madurez_12 = 1 THEN NULL WHEN max_dm_12 > 60 OR ev_12 = 1 THEN 1 ELSE 0 END AS target_12m_60,
  CASE WHEN falla_madurez_01 = 1 THEN NULL WHEN max_dm_01 > 30 OR ev_01 = 1 THEN 1 ELSE 0 END AS target_01m_30,
  CASE WHEN falla_madurez_02 = 1 THEN NULL WHEN max_dm_02 > 30 OR ev_02 = 1 THEN 1 ELSE 0 END AS target_02m_30,
  CASE WHEN falla_madurez_03 = 1 THEN NULL WHEN max_dm_03 > 30 OR ev_03 = 1 THEN 1 ELSE 0 END AS target_03m_30,
  CASE WHEN falla_madurez_04 = 1 THEN NULL WHEN max_dm_04 > 30 OR ev_04 = 1 THEN 1 ELSE 0 END AS target_04m_30,
  CASE WHEN falla_madurez_05 = 1 THEN NULL WHEN max_dm_05 > 30 OR ev_05 = 1 THEN 1 ELSE 0 END AS target_05m_30,
  CASE WHEN falla_madurez_06 = 1 THEN NULL WHEN max_dm_06 > 30 OR ev_06 = 1 THEN 1 ELSE 0 END AS target_06m_30,
  CASE WHEN falla_madurez_07 = 1 THEN NULL WHEN max_dm_07 > 30 OR ev_07 = 1 THEN 1 ELSE 0 END AS target_07m_30,
  CASE WHEN falla_madurez_08 = 1 THEN NULL WHEN max_dm_08 > 30 OR ev_08 = 1 THEN 1 ELSE 0 END AS target_08m_30,
  CASE WHEN falla_madurez_09 = 1 THEN NULL WHEN max_dm_09 > 30 OR ev_09 = 1 THEN 1 ELSE 0 END AS target_09m_30,
  CASE WHEN falla_madurez_10 = 1 THEN NULL WHEN max_dm_10 > 30 OR ev_10 = 1 THEN 1 ELSE 0 END AS target_10m_30,
  CASE WHEN falla_madurez_11 = 1 THEN NULL WHEN max_dm_11 > 30 OR ev_11 = 1 THEN 1 ELSE 0 END AS target_11m_30,
  CASE WHEN falla_madurez_12 = 1 THEN NULL WHEN max_dm_12 > 30 OR ev_12 = 1 THEN 1 ELSE 0 END AS target_12m_30
FROM mad
