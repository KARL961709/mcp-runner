-- d_schema_enr. Esquema de las tablas enr_admtcbk (llaves + presencia de dsc_flg_malo_12m / flg_clean),
--   para saber por que llave joinear y cual tabla trae la categoria desplegada. READ-ONLY.
SELECT table_name, ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner'
  AND table_name IN ('enr_admtcbk_1_v2', 'enr_admtcbk_2_v2')
  AND (column_name LIKE '%value%'
       OR column_name LIKE '%dsc_flg%'
       OR column_name IN ('tip_doc', 'cod_tip_doc', 'codmes', 'flg_clean', 'flg_ibk', 'cod_instit_financiera', 'sbs_value'))
ORDER BY table_name, ordinal_position
