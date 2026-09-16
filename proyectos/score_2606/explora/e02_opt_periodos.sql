-- e02 periodos opt. Cobertura por codmes x p_codmes. n, dni aprox, prob no nula, dominio tipdoc. Scan opt full.
SELECT CAST(codmes AS varchar) AS codmes, CAST(p_codmes AS varchar) AS p_codmes,
       COUNT(*) AS n,
       approx_distinct(key_value) AS n_dni_aprox,
       SUM(CASE WHEN probabilidad IS NOT NULL THEN 1 ELSE 0 END) AS n_prob,
       COUNT(DISTINCT CAST(cod_tip_doc AS varchar)) AS n_tipdoc
FROM disc_riesgos.scr_vcbankv3_repro_opt_
GROUP BY CAST(codmes AS varchar), CAST(p_codmes AS varchar)
ORDER BY codmes, p_codmes
