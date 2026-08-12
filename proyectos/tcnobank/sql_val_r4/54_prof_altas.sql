-- 54_prof_altas.sql | profundidad de las dos tablas de altas. Es el eslabon que puede cortar la serie larga: si arrancan en 2022 no hay poblacion para 2018 por mas RCC que haya
SELECT 'tng_altas_ssff_rsk'    AS tabla,
       count(*)                AS n_meses,
       min(p_codmes)           AS codmes_min,
       max(p_codmes)           AS codmes_max
FROM "e_perm_aws"."tng_altas_ssff_rsk$partitions"
UNION ALL
SELECT 'tng_altas_ibk_rsk',
       count(*),
       min(p_codmes),
       max(p_codmes)
FROM "e_perm_aws"."tng_altas_ibk_rsk$partitions"
ORDER BY tabla
