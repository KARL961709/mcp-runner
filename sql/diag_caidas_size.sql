-- diag_caidas_size | grano de las caidas: filas y key_value distintas (confirma que key_value existe y si hay dups). Agregado.
SELECT COUNT(*) AS n_filas, COUNT(DISTINCT key_value) AS n_keys FROM disc_model_owner.caidas_202608_admbank
