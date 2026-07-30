-- k01 ESQUEMA de scr_vcadmbnk_hist_rsk por nombre exacto -- respaldo si k03 falla por nombre de columna
SELECT ordinal_position, column_name, data_type, extra_info
FROM information_schema.columns
WHERE table_schema = 'd_perm_aws' AND table_name = 'scr_vcadmbnk_hist_rsk'
ORDER BY ordinal_position
LIMIT 100
