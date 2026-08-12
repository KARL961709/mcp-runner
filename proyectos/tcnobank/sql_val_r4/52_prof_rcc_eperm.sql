-- 52_prof_rcc_eperm.sql | profundidad del RCC en e_perm_aws leyendo SOLO metadata de particiones, sin escanear datos. Define hasta donde se puede construir la serie larga de tasa de default
SELECT substr(p_codmes, 1, 4)   AS anio,
       count(*)                 AS n_meses,
       min(p_codmes)            AS codmes_min,
       max(p_codmes)            AS codmes_max
FROM "e_perm_aws"."t_fact_report_rcc_rsk$partitions"
GROUP BY substr(p_codmes, 1, 4)
ORDER BY anio
