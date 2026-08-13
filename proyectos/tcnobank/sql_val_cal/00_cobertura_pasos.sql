-- ============================================================================
-- 00. COBERTURA Y GRANO DE CADA PASO MATERIALIZADO
-- ============================================================================
SELECT '05_rcc_agg' AS paso, count(*) AS n_filas, count(DISTINCT codmes) AS meses
FROM disc_model_owner.ds_adm_vcnbank_tc_05_rcc_agg
UNION ALL
SELECT '10_po' AS paso, count(*) AS n_filas, count(DISTINCT codmes_mrm) AS meses
FROM disc_model_owner.ds_adm_vcnbank_tc_10_po
UNION ALL
SELECT '11_po_key' AS paso, count(*) AS n_filas, count(DISTINCT codmes_mrm) AS meses
FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
UNION ALL
SELECT '12_saldo_perfil', count(*), count(DISTINCT codmes_mrm)
FROM disc_model_owner.ds_adm_vcnbank_tc_12_saldo_perfil
UNION ALL
SELECT '81_macro', count(*), count(DISTINCT codmes)
FROM disc_model_owner.ds_adm_vcnbank_tc_81_macro
UNION ALL
SELECT '13_pasivos', count(*), count(DISTINCT codmes_mrm)
FROM disc_model_owner.ds_adm_vcnbank_tc_13_pasivos
UNION ALL
SELECT '14_plin', count(*), count(DISTINCT codmes_mrm)
FROM disc_model_owner.ds_adm_vcnbank_tc_14_plin
UNION ALL
SELECT '15_cta_sueldo', count(*), count(DISTINCT codmes_mrm)
FROM disc_model_owner.ds_adm_vcnbank_tc_15_cta_sueldo
UNION ALL
SELECT '16_nodo', count(*), count(DISTINCT codmes_mrm)
FROM disc_model_owner.ds_adm_vcnbank_tc_16_nodo
UNION ALL
SELECT '20_rcc_base' AS paso, count(*) AS n_filas, count(DISTINCT codmes_mrm) AS meses
FROM disc_model_owner.ds_adm_vcnbank_tc_20_rcc_base
UNION ALL
SELECT '21_rcc_flags' AS paso, count(*) AS n_filas, count(DISTINCT codmes_mrm) AS meses
FROM disc_model_owner.ds_adm_vcnbank_tc_21_rcc_flags
UNION ALL
SELECT '30_drivers' AS paso, count(*) AS n_filas, count(DISTINCT codmes_mrm) AS meses
FROM disc_model_owner.ds_adm_vcnbank_tc_30_drivers
UNION ALL
SELECT '40_pdraw' AS paso, count(*) AS n_filas, count(DISTINCT codmes_mrm) AS meses
FROM disc_model_owner.ds_adm_vcnbank_tc_40_pdraw
UNION ALL
SELECT '50_targets' AS paso, count(*) AS n_filas, count(DISTINCT codmes_mrm) AS meses
FROM disc_model_owner.ds_adm_vcnbank_tc_50_targets
UNION ALL
SELECT '60_filtros' AS paso, count(*) AS n_filas, count(DISTINCT codmes_mrm) AS meses
FROM disc_model_owner.ds_adm_vcnbank_tc_60_filtros
UNION ALL
SELECT '65_dedup' AS paso, count(*) AS n_filas, count(DISTINCT codmes_mrm) AS meses
FROM disc_model_owner.ds_adm_vcnbank_tc_65_dedup
UNION ALL
SELECT 'cal' AS paso, count(*) AS n_filas, count(DISTINCT codmes_mrm) AS meses
FROM disc_model_owner.ds_adm_vcnbank_tc_cal
ORDER BY paso
