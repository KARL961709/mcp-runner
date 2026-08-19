-- t1 | Esquema de la tabla de altas candidata t_dsmb_pp_7339. READ-ONLY.
--   Busco: mes (codmes), key_value, subproducto, codempresa, flags swap/cima, desembolso.
SELECT column_name, data_type, ordinal_position
FROM information_schema.columns
WHERE table_schema = 'd_perm_aws' AND table_name = 't_dsmb_pp_7339'
ORDER BY ordinal_position
