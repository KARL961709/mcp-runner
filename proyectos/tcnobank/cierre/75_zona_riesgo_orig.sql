-- 75_zona_riesgo_orig.sql | zona_riesgo_orig da 'Rechazo' en el 97.76 por ciento de una tabla de altas APROBADAS, lo que no puede leerse literal. Se mira su evolucion y su cruce con zona_riesgo_cal y nivel_buro para distinguir entre campo mal poblado, semantica distinta o cambio de definicion en el tiempo
SELECT substr(p_codmes, 1, 4)                                                        AS anio,
       zona_riesgo_orig,
       zona_riesgo_cal,
       count(*)                                                                      AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY substr(p_codmes, 1, 4)), 2) AS pct_anio,
       count(DISTINCT nivel_buro)                                                    AS n_niv_buro
FROM e_perm_aws.t_rsk_fct_altas_tc
WHERE p_codmes IN ('202112', '202212', '202312', '202412', '202512')
GROUP BY substr(p_codmes, 1, 4), zona_riesgo_orig, zona_riesgo_cal
ORDER BY anio, n DESC
LIMIT 80
