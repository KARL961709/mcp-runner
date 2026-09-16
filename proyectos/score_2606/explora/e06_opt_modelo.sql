-- e06 dominio modelo/segmento/grupo_calibracion y si la calibracion ya viene llena. Scan opt full.
SELECT modelo, segmento, grupo_calibracion,
       COUNT(*) AS n,
       approx_distinct(key_value) AS n_dni_aprox,
       SUM(CASE WHEN prob_model IS NOT NULL THEN 1 ELSE 0 END) AS n_prob_model,
       SUM(CASE WHEN prob_modelo_cal IS NOT NULL AND prob_modelo_cal <> '' THEN 1 ELSE 0 END) AS n_cal_lleno
FROM disc_riesgos.scr_vcbankv3_repro_opt_
GROUP BY modelo, segmento, grupo_calibracion
ORDER BY n DESC
