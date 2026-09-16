-- e02 periodos opt. Cobertura por cod_mes x p_codmes. n, dni aprox, prob_model no nula, dominio modelo/tipdoc. Scan opt full.
SELECT CAST(cod_mes AS varchar) AS cod_mes, CAST(p_codmes AS varchar) AS p_codmes,
       COUNT(*) AS n,
       approx_distinct(key_value) AS n_dni_aprox,
       SUM(CASE WHEN prob_model IS NOT NULL THEN 1 ELSE 0 END) AS n_prob,
       COUNT(DISTINCT modelo) AS n_modelo,
       COUNT(DISTINCT CAST(cod_tip_doc AS varchar)) AS n_tipdoc
FROM disc_riesgos.scr_vcbankv3_repro_opt_
GROUP BY CAST(cod_mes AS varchar), CAST(p_codmes AS varchar)
ORDER BY cod_mes, p_codmes
