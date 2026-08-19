-- =====================================================================================
-- h1 | ESQUEMA de la tabla calibrada multi-mes 2606-2608. READ-ONLY.
--   Confirma: columna de mes (codmes / p_codmes), subproducto, prob_modelo (raw),
--   prob_modelo_cal_ppfacil (PIT), trf_* (drivers). Con eso derivo las 3 PD por mes.
-- =====================================================================================
SELECT column_name, data_type, ordinal_position
FROM information_schema.columns
WHERE table_schema = 'd_perm_aws' AND table_name = 'scr_vcadmbnk_hist_rsk_cal_2606_2608'
ORDER BY ordinal_position
