-- desemb_corrm_c1_conteo.sql | conteo de las 2 maestras corregidas vs base corregida (deben ser iguales). Agregado.
SELECT 'conteo' AS chk,
  (SELECT COUNT(*) FROM disc_model_owner.b46029_desemb_maestra_corrv1_202609) AS n_v1,
  (SELECT COUNT(*) FROM disc_model_owner.b46029_desemb_maestra_corrv2_202609) AS n_v2,
  (SELECT COUNT(*) FROM disc_model_owner.b46029_desemb_cal_corr_202609) AS n_base
