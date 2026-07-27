-- ============================================================================
-- M3. U3 - LAG DE DISPONIBILIDAD DE tipo_ingreso.
--     Query_PO_calib#L302 lo joinea en periodo = codmes_mrm, o sea t0 sin
--     rezago. Si p_fecinformacion del periodo M cae despues de M, en produccion
--     ese dato no estaba al decidir: seria CASO 2 y hay que relaguear.
-- ============================================================================
SELECT
  CAST(periodo AS VARCHAR)                                                        AS periodo,
  COUNT(*)                                                                        AS n,
  MIN(DATE_FORMAT(DATE_PARSE(CAST(p_fecinformacion AS VARCHAR), '%Y%m%d'), '%Y%m')) AS fecinf_mes_min,
  MAX(DATE_FORMAT(DATE_PARSE(CAST(p_fecinformacion AS VARCHAR), '%Y%m%d'), '%Y%m')) AS fecinf_mes_max,
  SUM(CASE WHEN DATE_FORMAT(DATE_PARSE(CAST(p_fecinformacion AS VARCHAR), '%Y%m%d'), '%Y%m') > CAST(periodo AS VARCHAR)
           THEN 1 ELSE 0 END)                                                     AS n_posterior_al_periodo
FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
WHERE CAST(periodo AS INT) IN (202301, 202306, 202401, 202406, 202501, 202506)
  AND CAST(numcarga AS INT) = 1
GROUP BY 1
ORDER BY 1
