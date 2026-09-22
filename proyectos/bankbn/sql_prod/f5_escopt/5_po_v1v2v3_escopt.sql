-- 5_po_v1v2v3_escopt.sql | tabla b46029_po_scoring_v1v2v3_202607: v1/v2 de la PO de altas + v3 = prob_modelo_cal de la scr (dedup fec_replica) + prob_modelo_esc_opt (escenario optimista = v3 x factor anti-conservador por personeria) y su puntuacion. FACTORES v202608: PJJ 0.65 (medido en IBK, count-weighted) / PNN 0.79 (adoptado del benchmark RESTO_TOP4 top-4 >=50k por muestra chica del PNN propio de IBK; CAVEAT: sub-predice ~1.7pp la mora observada de IBK, decision de metodologia documentada). El factor se aplica sobre v3 (base sobre la que se midio el 0.79). Si la tabla existe, correr antes el DROP (0_drop_v1v2v3_escopt.sql)
CREATE TABLE disc_model_owner.b46029_po_scoring_v1v2v3_202607
WITH (format = 'PARQUET', parquet_compression = 'SNAPPY', partitioned_by = ARRAY['p_codmes']) AS
WITH v3_dedup AS (
  SELECT p_codmes, tip_doc, key_value, prob_modelo_cal, puntuacion_modelo, flg_clean,
         ROW_NUMBER() OVER (PARTITION BY p_codmes, tip_doc, key_value ORDER BY fec_replica DESC) AS rn
  FROM disc_model_owner.scr_admbankbpe_calibrado_202607
  WHERE p_codmes IN ('202606', '202607')
)
SELECT
  a.codmes_alta AS codmes,
  a.tip_doc,
  a.key_value,
  a.personeria,
  a.prob_modelo,
  a.fhat,
  a.ft_meses_usados,
  a.prob_modelo_cal_v1,
  a.puntuacion_cal_v1,
  a.grupos_cal_v1,
  a.flg_clean,
  a.flg_impulsa_bwd,
  a.flg_reactiva_puro,
  a.prob_modelo_cal_v2,
  a.puntuacion_cal_v2,
  a.grupos_cal_v2,
  v3.prob_modelo_cal AS prob_modelo_cal_v3,
  v3.puntuacion_modelo AS puntuacion_cal_v3,
  v3.flg_clean AS flg_clean_v3,
  greatest(1e-6, least(1 - 1e-6,
    v3.prob_modelo_cal * CASE WHEN a.personeria = 'PJJ' THEN 0.65000 ELSE 0.79000 END)) AS prob_modelo_esc_opt,
  cast(round((1.0 - greatest(1e-6, least(1 - 1e-6,
    v3.prob_modelo_cal * CASE WHEN a.personeria = 'PJJ' THEN 0.65000 ELSE 0.79000 END))) * 1000) AS integer) AS puntuacion_esc_opt,
  a.p_codmes
FROM disc_model_owner.b46029_po_scoring_v1v2_202607 a
LEFT JOIN v3_dedup v3
  ON cast(v3.p_codmes AS int) = a.p_codmes
 AND v3.tip_doc = a.tip_doc
 AND v3.key_value = a.key_value
 AND v3.rn = 1
WHERE a.p_codmes IN (202606, 202607)
