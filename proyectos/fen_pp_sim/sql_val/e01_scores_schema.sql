-- e01_scores_schema.sql | columnas de la tabla de scores 2609: ver que PD hay (raw/ttc/pit/cal) y cual es la llave
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'd_perm_aws'
  AND table_name = 'scr_vcadmbnk_final_rsk_cal_2609'
ORDER BY ordinal_position
