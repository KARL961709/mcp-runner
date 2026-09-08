-- V7b. Cuadre del SCR calibrado (disc_model_owner.scr_cppibkren_cal, salida del job)
--      vs el scoreo vigente (d_perm_aws.scr_stk_ree_pp_cal_202607, codmes=202606), por cliente.
--      Confirma la CALIBRACION de punta a punta:
--        pd_raw  = prob_modelo (pkl) vs probabilidad (pd stored)   -> cierra pkl==stored
--        pd_cal  = prob_modelo_cal (nuestro) vs prob_modelo_cal (vigente) -> la calibracion
--        punt_cal= puntuacion_cal (entero)
--      Requiere que el notebook haya registrado disc_model_owner.scr_cppibkren_cal.
WITH scr AS (
  SELECT CAST(key_value AS VARCHAR)                                    AS key_value,
         CAST(cod_tip_doc AS VARCHAR)                                  AS tip_doc,
         CAST(prob_modelo AS DOUBLE)                                   AS pd_raw,
         CAST(prob_modelo_cal AS DOUBLE)                               AS pd_cal,
         CAST(puntuacion_cal AS DOUBLE)                                AS punt_cal
    FROM disc_model_owner.scr_cppibkren_cal
   WHERE CAST(cod_mes AS VARCHAR) = '202606'
),
vig AS (
  SELECT CAST(key_value AS VARCHAR)                                    AS key_value,
         CAST(tip_doc AS VARCHAR)                                      AS tip_doc,
         GREATEST(LEAST(CAST(probabilidad AS DOUBLE), 1.0 - 1e-9), 1e-9) AS pd_raw_v,
         CAST(prob_modelo_cal AS DOUBLE)                               AS pd_cal_v,
         CAST(puntuacion_cal AS DOUBLE)                                AS punt_cal_v
    FROM d_perm_aws.scr_stk_ree_pp_cal_202607
   WHERE CAST(codmes AS VARCHAR) = '202606'
),
j AS (
  SELECT s.pd_raw, s.pd_cal, s.punt_cal, v.pd_raw_v, v.pd_cal_v, v.punt_cal_v
    FROM scr s
    JOIN vig v
      ON v.key_value = s.key_value
     AND v.tip_doc   = s.tip_doc
)
SELECT (SELECT COUNT(*) FROM scr)                                      AS n_scr,
       (SELECT COUNT(*) FROM vig)                                      AS n_vig,
       COUNT(*)                                                        AS n_cruce,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM scr), 4)         AS pct_cruce,
       MAX(ABS(pd_raw   - pd_raw_v))                                   AS max_dif_pd_raw,
       MAX(ABS(pd_cal   - pd_cal_v))                                   AS max_dif_pd_cal,
       AVG(ABS(pd_cal   - pd_cal_v))                                   AS avg_dif_pd_cal,
       MAX(ABS(punt_cal - punt_cal_v))                                 AS max_dif_punt_cal
  FROM j
