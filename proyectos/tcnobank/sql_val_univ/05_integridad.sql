-- 05. INTEGRIDAD: nulos, rangos y dominios de TODA columna
--   la 01 solo miraba score y nodo. Aca se revisan las 21, mas los rangos que
--   una cadena de probabilidades puede romper sin dar error: una PD fuera de
--   (0,1) o una puntuacion fuera de 0-1000 salen de un log o un cdf mal armado
--   y no levantan excepcion, se escriben
SELECT COUNT(*)                                                                   AS n,
       SUM(CASE WHEN tip_doc         IS NULL THEN 1 ELSE 0 END)                   AS nul_tip_doc,
       SUM(CASE WHEN id_value        IS NULL THEN 1 ELSE 0 END)                   AS nul_id_value,
       SUM(CASE WHEN pd_raw          IS NULL THEN 1 ELSE 0 END)                   AS nul_pd_raw,
       SUM(CASE WHEN prob_modelo_cal IS NULL THEN 1 ELSE 0 END)                   AS nul_pd_cal,
       SUM(CASE WHEN puntuacion_cal  IS NULL THEN 1 ELSE 0 END)                   AS nul_punt_cal,
       SUM(CASE WHEN nodo_calc       IS NULL THEN 1 ELSE 0 END)                   AS nul_nodo,
       SUM(CASE WHEN macro_proy      IS NULL THEN 1 ELSE 0 END)                   AS nul_macro_proy,
       SUM(CASE WHEN seg_arq_salud   IS NULL THEN 1 ELSE 0 END)                   AS nul_arquetipo,
       SUM(CASE WHEN pd_raw IS NOT NULL AND prob_modelo_cal IS NULL
                THEN 1 ELSE 0 END)                                                AS viol_pdraw_sin_cal,
       SUM(CASE WHEN prob_modelo_cal <= 0 OR prob_modelo_cal >= 1
                THEN 1 ELSE 0 END)                                                AS viol_pd_fuera_01,
       SUM(CASE WHEN pd_raw <= 0 OR pd_raw >= 1 THEN 1 ELSE 0 END)                AS viol_pdraw_fuera_01,
       SUM(CASE WHEN puntuacion_cal < 0 OR puntuacion_cal > 1000
                THEN 1 ELSE 0 END)                                                AS viol_punt_rango,
       SUM(CASE WHEN nodo_calc NOT IN ('N1', 'N2', 'N3') THEN 1 ELSE 0 END)       AS viol_nodo_dominio,
       SUM(CASE WHEN macro_proy NOT IN (0, 1) THEN 1 ELSE 0 END)                  AS viol_macro_dominio,
       SUM(CASE WHEN ctrl_nodo_n_fuentes < 0 OR ctrl_nodo_n_fuentes > 3
                THEN 1 ELSE 0 END)                                                AS viol_n_fuentes,
       SUM(CASE WHEN puntuacion_cal <> CAST(FLOOR(1000 * (1 - prob_modelo_cal)) AS INTEGER)
                THEN 1 ELSE 0 END)                                                AS viol_punt_vs_pd
  FROM disc_model_owner.scr_univ_vcnbank_tc_cal
