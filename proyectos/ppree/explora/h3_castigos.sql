-- ============================================================================
-- H3. A13 - t_sco_maestro_cl_rsk: fecha de ingreso a cobranza judicial, unica
--     fuente del castigo (componente de evento duro del target).
-- ============================================================================
SELECT
  SUBSTR(DATE_FORMAT(ingreso_cj_fc, '%Y%m'), 1, 4)                     AS anio,
  COUNT(*)                                                             AS n,
  COUNT(DISTINCT DATE_FORMAT(ingreso_cj_fc, '%Y%m'))                   AS n_meses_con_filas,
  MIN(DATE_FORMAT(ingreso_cj_fc, '%Y%m'))                              AS mes_min,
  MAX(DATE_FORMAT(ingreso_cj_fc, '%Y%m'))                              AS mes_max,
  COUNT(DISTINCT CAST(cod_cuc AS VARCHAR))                             AS n_cuc,
  SUM(CASE WHEN cod_cuc IS NULL THEN 1 ELSE 0 END)                     AS n_cuc_null
FROM e_perm_aws.t_sco_maestro_cl_rsk
WHERE ingreso_cj_fc IS NOT NULL
  AND DATE_FORMAT(ingreso_cj_fc, '%Y%m') BETWEEN '201901' AND '202212'
GROUP BY 1
ORDER BY 1
