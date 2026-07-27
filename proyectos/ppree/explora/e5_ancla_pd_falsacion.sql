-- ============================================================================
-- E5. U2 - ANCLA DEL SCORE: dos alineaciones enfrentadas
--      A: B.codmes = codmes_mrm        (lo que hace Query_PO_calib.sql#L350)
--      B: B.codmes = codmes_mrm + 1    (lo que implica flg_colab.sql#L8)
--      Falsacion: la tabla de scoring trae su propio dsc_flg_malo_12m. La
--      alineacion correcta es la que concuerda con la madre; la otra no.
-- ============================================================================
WITH mad AS (
  SELECT
    CAST(codmes_mrm AS VARCHAR)                                                          AS codmes_mrm,
    DATE_FORMAT(DATE_PARSE(CAST(codmes_mrm AS VARCHAR), '%Y%m') + INTERVAL '1' MONTH, '%Y%m') AS codmes_mrm_p1,
    CAST(tip_doc AS VARCHAR)                                                             AS tip_doc,
    CAST(id_value AS VARCHAR)                                                            AS key_value,
    dsc_flg_malo_12m
  FROM disc_model_owner.enr_ds_flg_compppibk_rsk
  WHERE CAST(codmes_mrm AS VARCHAR) IN ('202406', '202412')
),
scr AS (
  SELECT
    CAST(codmes AS VARCHAR)      AS codmes,
    CAST(tip_doc AS VARCHAR)     AS tip_doc,
    CAST(key_value AS VARCHAR)   AS key_value,
    dsc_flg_malo_12m             AS dsc_scr,
    CAST(pd_comppp_reen_itc AS DOUBLE) AS pd
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov2_desencriptado
  WHERE CAST(codmes AS VARCHAR) IN ('202406', '202407', '202412', '202501')
)
SELECT
  m.codmes_mrm,
  COUNT(*)                                                                     AS n_madre,
  SUM(CASE WHEN a.key_value IS NOT NULL THEN 1 ELSE 0 END)                     AS n_cruce_A,
  SUM(CASE WHEN b.key_value IS NOT NULL THEN 1 ELSE 0 END)                     AS n_cruce_B,
  SUM(CASE WHEN a.dsc_scr = m.dsc_flg_malo_12m THEN 1 ELSE 0 END)              AS n_concuerda_A,
  SUM(CASE WHEN b.dsc_scr = m.dsc_flg_malo_12m THEN 1 ELSE 0 END)              AS n_concuerda_B,
  ROUND(AVG(a.pd), 6)                                                          AS pd_prom_A,
  ROUND(AVG(b.pd), 6)                                                          AS pd_prom_B
FROM mad m
LEFT JOIN scr a ON a.codmes = m.codmes_mrm    AND a.tip_doc = m.tip_doc AND a.key_value = m.key_value
LEFT JOIN scr b ON b.codmes = m.codmes_mrm_p1 AND b.tip_doc = m.tip_doc AND b.key_value = m.key_value
GROUP BY 1
ORDER BY 1
