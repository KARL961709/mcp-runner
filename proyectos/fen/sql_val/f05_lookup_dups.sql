-- f05 LLAVES DE NOMBRE duplicadas en la lookup (cada una multiplica filas de cartera en el join)
SELECT dep, prov, dist,
       count(*)                   AS n_filas,
       count(DISTINCT cod_ubigeo) AS n_ubigeo,
       min(r_label)               AS r_min,
       max(r_label)               AS r_max
FROM disc_model_owner.grado_elnino_lookup_v3
GROUP BY dep, prov, dist
HAVING count(*) > 1
ORDER BY 4 DESC, 1, 2, 3
