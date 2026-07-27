-- ============================================================================
-- 25. MORA EN EL SISTEMA FINANCIERO (RCC)
--   scope de cuentas OBLIGATORIO [ENR#L206]: sin el mide otra cosa (H55, factor 468)
--   union con corte 201812 / 201901 [H40, H52]
--   expone rcc_codmes (mes leido = t0-1) Y codmes (re-estampado +1 = t0) [ENR#L197] (P2)
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_25_sf AS
WITH rcc AS (
  SELECT CAST(codmes AS VARCHAR) AS rcc_codmes, CAST(key_value AS VARCHAR) AS id_value,
         CAST(tip_doc AS VARCHAR) AS tip_doc, condicion
  FROM d_perm_aws.t_fact_report_rcc_rsk
  WHERE CAST(codmes AS INT) = 201812
    AND SUBSTR(cod_cuenta_rcc, 1, 2) = '14'
    AND SUBSTR(cod_cuenta_rcc, 4, 1) IN ('1', '3', '4', '5', '6')
    AND tipo_credito IN ('01','02','03','04','05','06','07','08','09','10','11','12','13')
  UNION ALL
  SELECT CAST(codmes AS VARCHAR), CAST(key_value AS VARCHAR),
         CAST(tip_doc AS VARCHAR), condicion
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE CAST(codmes AS INT) BETWEEN 201901 AND 202605
    AND SUBSTR(cod_cuenta_rcc, 1, 2) = '14'
    AND SUBSTR(cod_cuenta_rcc, 4, 1) IN ('1', '3', '4', '5', '6')
    AND tipo_credito IN ('01','02','03','04','05','06','07','08','09','10','11','12','13')
)
SELECT
  DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(rcc_codmes, '%Y%m')), '%Y%m') AS codmes,
  rcc_codmes,
  id_value,
  tip_doc,
  MAX(CAST(condicion AS DOUBLE))                                            AS cond_max
FROM rcc
GROUP BY 1, 2, 3, 4
