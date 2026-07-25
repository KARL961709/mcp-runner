-- ============================================================================
-- BN 00. DISCOVERY FUENTES (altas / universo en d_perm/e_perm)
-- ============================================================================
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('d_perm_aws','e_perm_aws','disc_monitorian','disc_riesgos')
  AND (lower(table_name) LIKE '%admbankbpe%'
       OR lower(table_name) LIKE '%universo_bank%'
       OR lower(table_name) LIKE '%bpe%alta%')
ORDER BY table_schema, table_name
;
