-- n1 QA del marcado -- cobertura por poblacion y fuente. Esperado: STK 100% con ubigeo, ADM ~98.99%
SELECT poblacion, ubigeo_fuente, ubigeo_calidad,
       count(*)                                                            AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY poblacion), 2) AS pct_de_poblacion,
       round(100.0 * avg(CASE WHEN punto_calidad = 1 THEN 1 ELSE 0 END), 2) AS pct_con_punto,
       round(100.0 * avg(CASE WHEN r_label IS NOT NULL THEN 1 ELSE 0 END), 2) AS pct_con_zona
FROM disc_model_owner.fen_geo_marca_202607
GROUP BY poblacion, ubigeo_fuente, ubigeo_calidad
ORDER BY poblacion, ubigeo_calidad
