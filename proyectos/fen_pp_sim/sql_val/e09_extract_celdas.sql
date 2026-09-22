-- e09_extract_celdas.sql | EXTRACCION agregada para el simulador FEN de la campana PP 202609.
-- Grano: dep_inei (2 primeros del ubigeo INEI) x R_reest x grado_PIT (cortes 2609 sobre el score PIT).
-- Devuelve: n, las PD reales (raw / ttc / pit), score promedio, s indirecto, exposicion fisica y
-- min/max de pd_pit por celda (para derivar los bordes de grado en el artifact). El overlay FEN
-- (pit -> pit-fen) se calcula en el artifact; aqui solo salen agregados por celda, ningun cliente.
--
-- Puente confirmado (e08): substr(subject_id,3) = key_value  (subject_id = 66 chars, prefijo '1-', key_value = 64).
-- Campana deduplicada por llave: subject_id trae ~10k duplicados (2,512,001 filas / 2,501,992 distintos).
-- Mapeo de las 4 columnas del simulador:
--   PD raw = pd_raw | PD TTC = prob_modelo_ttc_cal_ppfacil | PD PIT = prob_modelo_cal_ppfacil
--   grado  = puntuacion_modelo_cal_ppfacil vs 985/955/947/912/892/864 | PD PIT-FEN = overlay (artifact)
SELECT
  COALESCE(substr(r.ubigeo_inei_nodo, 1, 2), '00') AS dep_inei,
  COALESCE(r.r_label_reest, 'SIN_R')               AS r_reest,
  COALESCE(CAST(r.r_nivel_reest AS varchar), '')   AS r_nivel,
  CASE
    WHEN u.puntuacion_modelo_cal_ppfacil >= 985 THEN 'G1'
    WHEN u.puntuacion_modelo_cal_ppfacil >= 955 THEN 'G2'
    WHEN u.puntuacion_modelo_cal_ppfacil >= 947 THEN 'G3'
    WHEN u.puntuacion_modelo_cal_ppfacil >= 912 THEN 'G4'
    WHEN u.puntuacion_modelo_cal_ppfacil >= 892 THEN 'G5'
    WHEN u.puntuacion_modelo_cal_ppfacil >= 864 THEN 'G6'
    ELSE 'GR'
  END                                              AS grado_pit,
  COUNT(*)                                                                         AS n,
  CAST(ROUND(AVG(u.pd_raw), 6) AS varchar)                                         AS pd_raw,
  CAST(ROUND(AVG(u.prob_modelo_ttc_cal_ppfacil), 6) AS varchar)                    AS pd_ttc,
  CAST(ROUND(AVG(u.prob_modelo_cal_ppfacil), 6) AS varchar)                        AS pd_pit,
  CAST(ROUND(AVG(CAST(u.puntuacion_modelo_cal_ppfacil AS double)), 1) AS varchar)  AS score_avg,
  CAST(ROUND(AVG(s.s_total), 4) AS varchar)                                        AS s_avg,
  CAST(ROUND(AVG(r.exp25), 4) AS varchar)                                          AS exp25_avg,
  CAST(ROUND(AVG(r.exp50), 4) AS varchar)                                          AS exp50_avg,
  CAST(ROUND(MIN(u.prob_modelo_cal_ppfacil), 6) AS varchar)                        AS pd_pit_min,
  CAST(ROUND(MAX(u.prob_modelo_cal_ppfacil), 6) AS varchar)                        AS pd_pit_max
FROM (
  SELECT DISTINCT substr(subject_id, 3) AS kv
  FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
  WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
) c
JOIN      d_perm_aws.scr_vcadmbnk_final_rsk_cal_2609 u ON u.key_value = c.kv
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest  r ON r.key_value = c.kv
LEFT JOIN disc_model_owner.fen_s_indirecto           s ON s.ubigeo    = r.ubigeo_inei_nodo
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2, 4
