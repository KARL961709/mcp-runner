-- 02_cols_flg_actual.sql | esquema de la tabla de flags del modelo vigente, para no adivinar nombres ni tipos en las lecturas siguientes
SELECT ordinal_position,
       column_name,
       data_type
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws'
  AND table_name = 'ds_flg_admtcnobk1_rsk'
ORDER BY ordinal_position
