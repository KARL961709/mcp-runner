-- 55_profundidad_exclusiones.sql | profundidad de las fuentes de exclusion. Cada una que arranque tarde obliga a decidir si el filtro rige solo desde ahi o si se acepta el hueco en los primeros anios de la serie
SELECT 't_consolidado_rsk'            AS fuente, count(*) AS n_meses, min(p_codmes) AS codmes_min, max(p_codmes) AS codmes_max
FROM "e_perm_aws"."t_consolidado_rsk$partitions"
UNION ALL
SELECT 't_cob_facilidades_ejecutadas', count(*), min(p_periodo), max(p_periodo)
FROM "e_perm_aws"."t_cob_facilidades_ejecutadas$partitions"
UNION ALL
SELECT 't_ubigeo_hist', count(*), min(p_codmes), max(p_codmes)
FROM "e_perm_aws"."t_ubigeo_hist$partitions"
ORDER BY fuente
