-- ============================================================================
-- BN 06. DISCOVERY FUENTE flg_impulsa (filtro de calibracion)
-- ============================================================================
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('d_perm_aws','e_perm_aws','disc_monitorian','disc_riesgos')
  AND lower(table_name) LIKE '%impulsa%'
ORDER BY table_schema, table_name
;
