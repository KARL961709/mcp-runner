-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : M_mapeo/M0_estructura.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\M0_estructura.sql
--   sha256  : 7c4754566a5f   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : solo metadata: instantaneo y sin riesgo. Correr primero
-- =====================================================================================
-- =====================================================================================
-- M0_estructura.sql | estructura de las 12 fuentes, en una fila cada una
--
-- CORRER PRIMERO. Solo lee metadata: no toca una sola fila de dato, es instantaneo
-- y no tiene riesgo. Existe para no adivinar nombres de columna en M1/M2.
--
-- RESPONDE TRES COSAS
--   1. que columnas tiene cada fuente, en orden
--   2. si t_mst_bpe_giros_restringidos tiene ALGUNA columna de versionado que no
--      estemos usando (codmes, vigencia, fecha_corte, periodo...). Hoy se lee sin
--      corte de fecha, y es la unica de las 12 asi. Si aparece una columna de fecha
--      aqui, el problema de reproducibilidad se arregla solo.
--   3. si el RCC de d_perm_aws tiene el mismo esquema que el de e_perm_aws
--
-- 12 filas. READ-ONLY.
-- =====================================================================================

SELECT
  table_schema || '.' || table_name                                       AS fuente,
  count(*)                                                                AS n_columnas,
  array_join(array_agg(column_name ORDER BY ordinal_position), ', ')      AS columnas
FROM information_schema.columns
WHERE (table_schema = 'e_perm_aws' AND table_name IN (
         'scr_admbankbpe_rsk',
         't_fact_report_rcc_rsk',
         't_mst_princ_sunat_rsk',
         't_mst_sec_sunat_rsk',
         't_mst_bpe_giros_restringidos',
         't_mst_reniec_rsk',
         't_mst_rep_legal_sunat_rsk',
         't_rel_vpc_myp_clientenegativo',
         't_mst_vpc_myp_cliente_actual'))
   OR (table_schema = 'd_perm_aws'       AND table_name = 't_fact_report_rcc_rsk')
   OR (table_schema = 'disc_model_owner' AND table_name IN (
         'bnbpe_ibk_calib_src', 'bnbpe_ibk_altas_src'))
   OR (table_schema = 'disc_monitorian'  AND table_name = 't_dan_mrm_admbankbpe_altas_rep')
GROUP BY 1
ORDER BY 1
