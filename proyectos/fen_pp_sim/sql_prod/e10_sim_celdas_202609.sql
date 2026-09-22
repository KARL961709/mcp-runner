-- e10_sim_celdas_202609.sql | CTAS de la tabla agregada para el simulador FEN de la campana PP 202609.
-- Crea disc_model_owner.fen_pp_sim_celdas_202609 (PARQUET, descargable). Grano: dep_inei x r_reest x grado_PIT.
-- COHERENTE POR GRUPO: es el grano mas fino; cada celda suma exacto a cualquier vista agregada
--   (por grado G1..GR, por R, por departamento, por grupo FEN golpeado/costa/interior).
-- Solo agregados (n y promedios por celda); ningun registro de cliente sale de la base.
--
-- Puente confirmado (e08): substr(subject_id,3) = key_value. Campana deduplicada por llave
--   (subject_id trae ~10k duplicados: 2,512,001 filas / 2,501,992 distintos).
-- Mapeo de columnas (verificado en scr_vcadmbnk_final_rsk_cal_2609, 31 cols):
--   pd_raw = pd_raw | pd_ttc = prob_modelo_ttc_cal_ppfacil | pd_pit = prob_modelo_cal_ppfacil
--   grado  = puntuacion_modelo_cal_ppfacil vs 985/955/947/912/892/864
-- Recuperacion = SOLO INFLACION; el rec_d por departamento se aplica en el artifact (no en SQL).
--
-- Correr de a uno:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_prod -Only e10_sim_celdas_202609
-- Si la tabla ya existe (rebuild), correr antes:  -Only e10b_drop_sim_celdas
CREATE TABLE disc_model_owner.fen_pp_sim_celdas_202609
WITH (format = 'PARQUET') AS
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
  COUNT(*)                                              AS n,
  AVG(u.pd_raw)                                         AS pd_raw,
  AVG(u.prob_modelo_ttc_cal_ppfacil)                   AS pd_ttc,
  AVG(u.prob_modelo_cal_ppfacil)                       AS pd_pit,
  AVG(CAST(u.puntuacion_modelo_cal_ppfacil AS double)) AS score_avg,
  AVG(s.s_total)                                        AS s_avg,
  AVG(r.exp25)                                          AS exp25_avg,
  AVG(r.exp50)                                          AS exp50_avg,
  MIN(u.prob_modelo_cal_ppfacil)                       AS pd_pit_min,
  MAX(u.prob_modelo_cal_ppfacil)                       AS pd_pit_max
FROM (
  SELECT DISTINCT substr(subject_id, 3) AS kv
  FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
  WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
) c
JOIN      d_perm_aws.scr_vcadmbnk_final_rsk_cal_2609 u ON u.key_value = c.kv
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest  r ON r.key_value = c.kv
LEFT JOIN disc_model_owner.fen_s_indirecto           s ON s.ubigeo    = r.ubigeo_inei_nodo
GROUP BY 1, 2, 3, 4
