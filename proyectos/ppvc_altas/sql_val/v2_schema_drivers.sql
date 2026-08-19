-- =====================================================================================
-- v2 | ESQUEMA de los drivers de altas PP_VC. READ-ONLY.
--   Objetivo: confirmar que pp_vc_drivers_admbnk2 trae los ejes de la cadena
--     (tipo_ingreso, flg_meses, flg_tc, rng_max_clasif, flag_cuenta_sueldo,
--      flag_pasivos, nodos_pp) y SI tiene columna de mes (codmes / p_codmes).
--   Clave: v7 (202606) une drivers SOLO por key_value -> si la tabla es de un
--   unico mes, 202605 no tendria drivers y habria que construirlos.
-- =====================================================================================
SELECT column_name, data_type, ordinal_position
FROM information_schema.columns
WHERE table_schema = 'disc_model_owner' AND table_name = 'pp_vc_drivers_admbnk2'
ORDER BY ordinal_position
