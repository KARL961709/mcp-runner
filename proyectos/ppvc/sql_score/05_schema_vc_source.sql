-- ============================================================================
-- 05. Esquema de d_perm_aws.scr_vcadmbnk_final_hist_rsk (fuente de pd_raw).
--     Para reflejar sus columnas en scr_ppvc_cal (+ sufijo _cal en las salidas).
-- ============================================================================
SELECT ordinal_position, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'd_perm_aws' AND table_name = 'scr_vcadmbnk_final_hist_rsk'
ORDER BY ordinal_position
