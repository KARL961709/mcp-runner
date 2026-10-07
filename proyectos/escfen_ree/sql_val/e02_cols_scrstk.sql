-- e02. columnas de disc_model_owner.scr_stk_ree_pp_cal_202610 (fuente NO_FREEZE)
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner' AND table_name = 'scr_stk_ree_pp_cal_202610'
ORDER BY ordinal_position
