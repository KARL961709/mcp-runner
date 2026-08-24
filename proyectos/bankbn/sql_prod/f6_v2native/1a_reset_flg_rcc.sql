-- 1a_reset_flg_rcc.sql | dropea la tabla nueva del pipeline v2 nativo (no toca b46029_po_*). Corre ANTES del create
DROP TABLE IF EXISTS disc_model_owner.b46029_v2n_flg_rcc_202607
