-- 53_profundidad_altas_fct.sql | profundidad de t_rsk_fct_altas_tc, la tabla gobernada de altas. Va SOLA y no dentro del lote de la 52 a proposito: es la incognita que decide si la poblacion se reconstruye sin depender de tng_altas, y no quiero que un hermano mal particionado la tumbe
SELECT substr(p_codmes, 1, 4)  AS anio,
       count(*)                AS n_meses,
       min(p_codmes)           AS codmes_min,
       max(p_codmes)           AS codmes_max
FROM "e_perm_aws"."t_rsk_fct_altas_tc$partitions"
GROUP BY substr(p_codmes, 1, 4)
ORDER BY anio
