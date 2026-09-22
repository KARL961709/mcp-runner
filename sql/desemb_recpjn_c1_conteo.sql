-- desemb_recpjn_c1_conteo.sql | conteo recpjn vs maestra REC (deben ser iguales, misma poblacion). Agregado.
SELECT 'conteo' AS chk,
  (SELECT COUNT(*) FROM disc_model_owner.b46029_desemb_maestra_recpjn_202609) AS n_recpjn,
  (SELECT COUNT(*) FROM disc_model_owner.b46029_desemb_maestra_rec_202609) AS n_rec
