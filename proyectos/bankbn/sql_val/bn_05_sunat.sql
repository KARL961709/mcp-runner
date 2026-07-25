-- ============================================================================
-- BN 05. ESTRUCTURA SUNAT (para PIT vs snapshot de estado/giro/ubigeo)
-- ============================================================================
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws'
  AND table_name IN ('t_mst_princ_sunat_rsk', 't_mst_sec_sunat_rsk')
ORDER BY table_name, ordinal_position
;
