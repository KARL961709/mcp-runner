-- chk_c_escopt.sql | cuenta filas y meses de disc_model_owner.b46029_v2n_escopt_202609 (ver si se purgaron los datos). Agregado.
SELECT COUNT(*) AS n, COUNT(DISTINCT p_codmes) AS meses, CAST(MIN(p_codmes) AS VARCHAR) AS min_p, CAST(MAX(p_codmes) AS VARCHAR) AS max_p FROM disc_model_owner.b46029_v2n_escopt_202609
