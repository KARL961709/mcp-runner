-- =====================================================================================
-- a0 | DISCOVERY: tablas madre de altas / desembolsos PP_VC. READ-ONLY.
--   pp_vc_altas (derivada) esta desactualizada (v9=0 en 2026). Busco la fuente madre
--   fresca a jun/jul/ago: desembolsos IBK y wrk SSFF.
-- =====================================================================================
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('d_perm_aws', 'disc_model_owner', 'e_perm_aws')
  AND ( table_name LIKE '%desembol%'
     OR table_name LIKE '%pp_vc_alta%'
     OR table_name LIKE '%gdp_rcc_ppe%' )
ORDER BY table_schema, table_name
