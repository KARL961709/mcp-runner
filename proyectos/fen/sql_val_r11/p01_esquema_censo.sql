-- p01 ESQUEMA del censo por nombre exacto -- para saber si trae ubigeo/dep/prov o solo punto+manzana
SELECT ordinal_position, column_name, data_type, extra_info
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws' AND table_name = 't_agg_censo_enrich_rsk'
ORDER BY ordinal_position
LIMIT 100
