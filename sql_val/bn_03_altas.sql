-- ============================================================================
-- BN 03. ESTRUCTURA ALTAS (columnas)
-- ============================================================================
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'disc_monitorian'
  AND table_name   = 't_dan_mrm_admbankbpe_altas_rep'
ORDER BY ordinal_position
;
