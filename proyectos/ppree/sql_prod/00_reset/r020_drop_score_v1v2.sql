-- reset | drop del scoring V1 y V2. El CTAS no lleva DROP: un CREATE TABLE
-- sobre una tabla existente falla, asi que este va primero para regenerar.
DROP TABLE IF EXISTS disc_model_owner.scr_stk_ree_pp_cal_v1v2
