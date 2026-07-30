-- n2 EXPOSICION FEN de las dos poblaciones con el grado v4 -- el numero para el comite
SELECT poblacion,
       coalesce(r_label, 'SIN_ZONA')                                       AS zona,
       count(*)                                                            AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY poblacion), 2) AS pct,
       round(100.0 * avg(CASE WHEN punto_calidad = 1 THEN 1 ELSE 0 END), 2) AS pct_con_punto,
       round(avg(pct_expuesto), 1)                                         AS exp_cenepred_prom
FROM disc_model_owner.fen_geo_marca_202607
GROUP BY poblacion, coalesce(r_label, 'SIN_ZONA')
ORDER BY poblacion, zona
