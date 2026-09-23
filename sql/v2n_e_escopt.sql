-- v2n_e_escopt.sql | V2 ESC OPT sobre el v2native (clean/dirty): prob_modelo_cal_v2_opt = prob_modelo_cal_v2 x factor (PJJ/tip_doc=2 0.68140 / PNN 0.96970), MISMO factor que 4_scr_escopt. Reproduce el _v2_opt de la enviada. Particionada por p_codmes.
CREATE TABLE disc_model_owner.b46029_v2n_escopt_202609
WITH (format='PARQUET', parquet_compression='SNAPPY', partitioned_by=ARRAY['p_codmes']) AS
SELECT s.tip_doc, s.key_value, s.personeria,
  s.prob_modelo_cal_v2,
  CAST(round((1.0-s.prob_modelo_cal_v2)*1000) AS INTEGER) AS puntuacion_cal_v2,
  greatest(1e-6, least(1-1e-6, s.prob_modelo_cal_v2 * CASE WHEN s.tip_doc='2' THEN 0.68140 ELSE 0.96970 END)) AS prob_modelo_cal_v2_opt,
  CAST(round((1.0 - greatest(1e-6, least(1-1e-6, s.prob_modelo_cal_v2 * CASE WHEN s.tip_doc='2' THEN 0.68140 ELSE 0.96970 END)))*1000) AS INTEGER) AS puntuacion_cal_v2_opt,
  s.p_codmes
FROM disc_model_owner.b46029_v2n_scoring_202609 s
