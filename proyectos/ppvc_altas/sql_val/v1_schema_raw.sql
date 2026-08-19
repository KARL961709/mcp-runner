-- =====================================================================================
-- v1 | ESQUEMA de la fuente RAW de altas PP_VC. READ-ONLY.
--   Objetivo: ver columnas y tipos de scr_vcadmbnk_hist_rsk:
--     - si trae probabilidad / puntuacion (raw), key_value, tip_doc, p_codmes
--     - si trae subproducto (para separar 5.P FACIL vs 4.CD)
--     - si YA trae columnas calibradas (prob_modelo_cal_ppfacil / puntuacion_cal_ppfacil)
--       -> de existir, nos ahorramos re-derivar la cadena PIT.
-- =====================================================================================
SELECT column_name, data_type, ordinal_position
FROM information_schema.columns
WHERE table_schema = 'd_perm_aws' AND table_name = 'scr_vcadmbnk_hist_rsk'
ORDER BY ordinal_position
