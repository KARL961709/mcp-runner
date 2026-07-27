-- ============================================================================
-- V1. G5 + grano. Cobertura de cada staging y duplicados al grano declarado.
--     Blanco fijo: 10_po debe dar 90 meses (201901-202606, H65).
--     Toda columna n_dup debe ser 0.
-- ============================================================================
SELECT 'ds_stk_ree_pp_10_po' AS tabla, COUNT(*) AS n,
       COUNT(DISTINCT codmes_mrm) AS n_meses, MIN(codmes_mrm) AS mn, MAX(codmes_mrm) AS mx,
       COUNT(*) - COUNT(DISTINCT codmes_mrm || '|' || tip_doc || '|' || id_value) AS n_dup
FROM disc_model_owner.ds_stk_ree_pp_10_po
UNION ALL
SELECT 'ds_stk_ree_pp_11_marca', COUNT(*), COUNT(DISTINCT codmes_mrm), MIN(codmes_mrm), MAX(codmes_mrm),
       COUNT(*) - COUNT(DISTINCT codmes_mrm || '|' || id_value)
FROM disc_model_owner.ds_stk_ree_pp_11_marca
UNION ALL
SELECT 'ds_stk_ree_pp_20_dm', COUNT(*), COUNT(DISTINCT codmes), MIN(codmes), MAX(codmes),
       COUNT(*) - COUNT(DISTINCT codmes || '|' || tip_doc || '|' || id_value)
FROM disc_model_owner.ds_stk_ree_pp_20_dm
UNION ALL
SELECT 'ds_stk_ree_pp_25_sf', COUNT(*), COUNT(DISTINCT codmes), MIN(codmes), MAX(codmes),
       COUNT(*) - COUNT(DISTINCT codmes || '|' || tip_doc || '|' || id_value)
FROM disc_model_owner.ds_stk_ree_pp_25_sf
UNION ALL
SELECT 'ds_stk_ree_pp_30_fut_a', COUNT(*), COUNT(DISTINCT codmes_mrm), MIN(codmes_mrm), MAX(codmes_mrm),
       COUNT(*) - COUNT(DISTINCT codmes_mrm || '|' || tip_doc || '|' || id_value)
FROM disc_model_owner.ds_stk_ree_pp_30_fut_a
UNION ALL
SELECT 'ds_stk_ree_pp_35_target', COUNT(*), COUNT(DISTINCT codmes_mrm), MIN(codmes_mrm), MAX(codmes_mrm),
       COUNT(*) - COUNT(DISTINCT codmes_mrm || '|' || tip_doc || '|' || id_value)
FROM disc_model_owner.ds_stk_ree_pp_35_target
UNION ALL
SELECT 'ds_stk_ree_pp_40_drivers', COUNT(*), COUNT(DISTINCT codmes_mrm), MIN(codmes_mrm), MAX(codmes_mrm),
       COUNT(*) - COUNT(DISTINCT codmes_mrm || '|' || tip_doc || '|' || id_value)
FROM disc_model_owner.ds_stk_ree_pp_40_drivers
UNION ALL
SELECT 'ds_stk_ree_pp_50_pd', COUNT(*), COUNT(DISTINCT codmes_mrm), MIN(codmes_mrm), MAX(codmes_mrm),
       COUNT(*) - COUNT(DISTINCT codmes_mrm || '|' || tip_doc || '|' || id_value)
FROM disc_model_owner.ds_stk_ree_pp_50_pd
ORDER BY 1
