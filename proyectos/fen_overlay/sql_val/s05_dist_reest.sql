-- s05_dist_reest: migracion uno-a-uno EXACTA por escenario (PEA, vista Geo r_reest). Por escenario x grado_base x grado_estres (sobre ppfacil) -> n, pd base y estres medios. Es el estres por CLIENTE agregado (NO el promedio de celda del motor) = el "verdadero cambio". La agregacion pesada la hace el banco sobre los 9,1M; solo sale este resumen. Full CSV en output\ (no depende del cap de 100). <=294 filas
SELECT escenario, grado_base_facil AS g0, grado_estres_facil AS g1,
  count(*) AS n,
  round(avg(pd_base_facil), 5)   AS pd0,
  round(avg(pd_estres_facil), 5) AS pd1
FROM disc_model_owner.fen_overlay_escenarios_202608_reest
GROUP BY escenario, grado_base_facil, grado_estres_facil
ORDER BY escenario, g0, g1
