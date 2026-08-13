-- ============================================================================
-- D22. COLUMNAS DE LAS FUENTES NUEVAS
--   scan: information_schema.columns
--   ancla: no se escribe un join contra columnas que no se leyeron. Interesa la llave
--          (key_value o cif_key), el periodo, y para AFP que campo marca el retiro
-- ============================================================================
SELECT table_schema,
       table_name,
       ordinal_position                                                                 AS pos,
       column_name,
       data_type
FROM information_schema.columns
WHERE (table_schema = 'e_perm_aws'
       AND table_name IN ('t_fact_edc_solicitud_retiro_afp_ibk','t_agg_retail_user_trx_plin',
                          't_mst_ctaibk_rsk'))
   OR (table_schema = 'disc_model_owner' AND lower(table_name) LIKE '%pasivos%')
ORDER BY table_schema, table_name, ordinal_position
LIMIT 100
