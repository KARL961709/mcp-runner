-- ============================================================================
-- V3. FRONTERA DE SCORING: hasta que codmes llega cada insumo (max crudo)
--   pd_v5       score month C
--   segmento    C - 1  (codmes_mrm)
--   macro_ipc   C - 6  (window lag5..lag10)
--   Mes tope de scoring = MIN( pd_max , segmento_max + 1 , macro_max + 6 )
-- ============================================================================
SELECT 'pd_v5'        AS insumo, MAX(CAST(codmes  AS VARCHAR)) AS codmes_max
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov5
 WHERE pd_comppp_reen_itc IS NOT NULL
UNION ALL
SELECT 'segmento_rtd' AS insumo, MAX(CAST(periodo AS VARCHAR)) AS codmes_max
  FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
 WHERE CAST(numcarga AS INT) = 1
UNION ALL
SELECT 'macro_ipc'    AS insumo, MAX(CAST(cod_mes AS VARCHAR)) AS codmes_max
  FROM e_perm_aws.t_mst_bcrp_rsk
 WHERE porc_ipc IS NOT NULL
 ORDER BY 1
