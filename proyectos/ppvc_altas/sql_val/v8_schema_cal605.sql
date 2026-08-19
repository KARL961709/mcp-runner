-- =====================================================================================
-- v8 | ESQUEMA de la tabla de altas calibradas 202605 (nombrada en el CSV de control).
--   Mismo objetivo que v7 para el mes de mayo (cobertura 82.7% segun el CSV).
--   READ-ONLY. Si no existe con este nombre, v6 da el real.
-- =====================================================================================
SELECT column_name, data_type, ordinal_position
FROM information_schema.columns
WHERE table_schema = 'd_perm_aws' AND table_name = 'scr_vc_orig_bank_calrcc_2_cal'
ORDER BY ordinal_position
