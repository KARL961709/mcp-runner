-- ============================================================================
-- V4. DENSIDAD DE LA COLA: ultimos meses de pd (v5) y del segmento (rtd)
--   confirma que el mes frontera es un mes completo y no una carga a medias
-- ============================================================================
SELECT 'pd_v5'        AS insumo,
       CAST(codmes AS VARCHAR)                        AS codmes,
       COUNT(*)                                       AS n
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov5
 WHERE pd_comppp_reen_itc IS NOT NULL
   AND CAST(codmes AS INTEGER) >= 202602
 GROUP BY 1, CAST(codmes AS VARCHAR)
UNION ALL
SELECT 'segmento_rtd' AS insumo,
       CAST(periodo AS VARCHAR)                       AS codmes,
       COUNT(DISTINCT SUBSTR(subject_id, 3))          AS n
  FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
 WHERE CAST(numcarga AS INT) = 1
   AND CAST(periodo AS INTEGER) >= 202602
 GROUP BY 1, CAST(periodo AS VARCHAR)
 ORDER BY 1, 2
