-- ============================================================================
-- V7. Cierra el hueco de G21: las 6 tablas de staging que ninguna otra QA toca.
--     Cobertura, grano y el hueco 202107 que 26_meses debe reportar AUSENTE.
-- ============================================================================
SELECT 'ds_stk_ree_pp_21_gh' AS tabla, COUNT(*) AS n, COUNT(DISTINCT codmes) AS n_meses,
       MIN(codmes) AS mn, MAX(codmes) AS mx,
       COUNT(*) - COUNT(DISTINCT codmes || '|' || tip_doc || '|' || id_value) AS n_dup
FROM disc_model_owner.ds_stk_ree_pp_21_gh
UNION ALL
SELECT 'ds_stk_ree_pp_22_rf', COUNT(*), COUNT(DISTINCT codmes), MIN(codmes), MAX(codmes),
       COUNT(*) - COUNT(DISTINCT codmes || '|' || tip_doc || '|' || id_value)
FROM disc_model_owner.ds_stk_ree_pp_22_rf
UNION ALL
SELECT 'ds_stk_ree_pp_23_cst', COUNT(*), COUNT(DISTINCT codmes), MIN(codmes), MAX(codmes),
       COUNT(*) - COUNT(DISTINCT codmes || '|' || tip_doc || '|' || id_value)
FROM disc_model_owner.ds_stk_ree_pp_23_cst
UNION ALL
SELECT 'ds_stk_ree_pp_24_colab', COUNT(*), COUNT(DISTINCT codmes), MIN(codmes), MAX(codmes),
       COUNT(*) - COUNT(DISTINCT codmes || '|' || tip_doc || '|' || id_value)
FROM disc_model_owner.ds_stk_ree_pp_24_colab
UNION ALL
SELECT 'ds_stk_ree_pp_26_meses', COUNT(*), COUNT(DISTINCT codmes), MIN(codmes), MAX(codmes),
       COUNT(*) - COUNT(DISTINCT codmes)
FROM disc_model_owner.ds_stk_ree_pp_26_meses
UNION ALL
SELECT 'ds_stk_ree_pp_30_fut_b', COUNT(*), COUNT(DISTINCT codmes_mrm), MIN(codmes_mrm), MAX(codmes_mrm),
       COUNT(*) - COUNT(DISTINCT codmes_mrm || '|' || tip_doc || '|' || id_value)
FROM disc_model_owner.ds_stk_ree_pp_30_fut_b
UNION ALL
SELECT 'HUECO_202107_en_26_meses', COUNT(*), 0, MIN(codmes), MAX(codmes), 0
FROM disc_model_owner.ds_stk_ree_pp_26_meses
WHERE codmes = '202107'
UNION ALL
SELECT 'PAR_30a_vs_30b', 0,
       (SELECT COUNT(*) FROM disc_model_owner.ds_stk_ree_pp_30_fut_a)
     - (SELECT COUNT(*) FROM disc_model_owner.ds_stk_ree_pp_30_fut_b),
       '-', '-', 0
ORDER BY 1
