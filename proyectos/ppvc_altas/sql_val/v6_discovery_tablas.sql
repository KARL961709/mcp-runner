-- =====================================================================================
-- v6 | DISCOVERY: tablas candidatas de altas / calibradas PP_VC. READ-ONLY.
--   Para ubicar los nombres reales de las tablas de altas por mes (202605/202606)
--   y cualquier variante *_cal / *_calrcc que ya tenga las PD calibradas.
-- =====================================================================================
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('d_perm_aws', 'disc_model_owner')
  AND ( table_name LIKE '%vcadmbnk%'
     OR table_name LIKE '%vc_orig%'
     OR table_name LIKE '%pp_vc%'
     OR table_name LIKE '%vc_cal%'
     OR table_name LIKE '%calrcc%' )
ORDER BY table_schema, table_name
