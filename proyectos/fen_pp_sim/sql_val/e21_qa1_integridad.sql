-- e21_qa1_integridad.sql | QA integridad de la tabla score indirecto nuevo (esperado: n=1891, distinct=1891, nulls=0, max_snorm=1.0)
SELECT COUNT(*) AS n_filas,
       COUNT(DISTINCT ubigeo) AS n_ubigeos,
       SUM(CASE WHEN ubigeo IS NULL THEN 1 ELSE 0 END) AS null_ubigeo,
       SUM(CASE WHEN s_norm IS NULL THEN 1 ELSE 0 END) AS null_snorm,
       SUM(CASE WHEN length(ubigeo) <> 6 THEN 1 ELSE 0 END) AS ubigeo_no6,
       ROUND(MIN(s_raw),4)  AS min_sraw,  ROUND(MAX(s_raw),4)  AS max_sraw,
       ROUND(AVG(s_raw),4)  AS avg_sraw,  ROUND(approx_percentile(s_raw,0.5),4) AS med_sraw,
       ROUND(MIN(s_norm),4) AS min_snorm, ROUND(MAX(s_norm),4) AS max_snorm
FROM disc_model_owner.fen_s_indirecto_empleo_2026