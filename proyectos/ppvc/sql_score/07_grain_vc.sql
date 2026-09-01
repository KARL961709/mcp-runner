-- ============================================================================
-- 07. Grano de scr_vcadmbnk_final_hist_rsk: filas, con prob, llaves duplicadas, modelos, rango.
-- ============================================================================
SELECT
  COUNT(*) AS n_filas,
  SUM(CASE WHEN probabilidad IS NOT NULL THEN 1 ELSE 0 END) AS n_con_prob,
  (SELECT COUNT(*) FROM (SELECT codmes, cod_tip_doc, key_value FROM d_perm_aws.scr_vcadmbnk_final_hist_rsk GROUP BY 1, 2, 3 HAVING COUNT(*) > 1) t) AS n_llaves_dup,
  COUNT(DISTINCT modelo) AS n_modelos,
  MIN(codmes) AS codmes_min, MAX(codmes) AS codmes_max
FROM d_perm_aws.scr_vcadmbnk_final_hist_rsk
