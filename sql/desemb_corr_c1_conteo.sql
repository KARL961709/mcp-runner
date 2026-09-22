-- desemb_corr_c1_conteo.sql | conteo base corregida vs base original (deben ser iguales, misma poblacion). Agregado.
SELECT 'conteo' AS chk,
  (SELECT COUNT(*) FROM disc_model_owner.b46029_desemb_cal_corr_202609) AS n_corr,
  (SELECT COUNT(*) FROM disc_model_owner.b46029_desemb_cal_202609) AS n_orig
