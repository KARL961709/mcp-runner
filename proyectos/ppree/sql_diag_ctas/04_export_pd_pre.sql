-- ============================================================================
-- 04. PARQUET PD PRE-DESEMBOLSO - perimetro reenganche, archivo D y D-1
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_px_pdpre
WITH (format = 'PARQUET', write_compression = 'SNAPPY',
      external_location = '<S3_DATOS>/pd_pre/') AS
WITH v AS (
  SELECT CAST(key_value AS VARCHAR) AS id_value, CAST(cod_tip_doc AS VARCHAR) AS tip_doc,
         CAST(codmes AS VARCHAR) AS codmes, MAX(pd_comppp_reen_itc) AS pd
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
  GROUP BY 1, 2, 3
)
SELECT
  g.codmes_mrm   AS codmes,
  g.tip_doc,
  g.id_value     AS key_value,
  v0.pd          AS pd_pre_d,
  v1.pd          AS pd_pre_dm1
FROM disc_model_owner.ds_stk_ree_pp_cal g
LEFT JOIN v v0 ON v0.id_value = g.id_value AND v0.tip_doc = g.tip_doc
             AND v0.codmes = g.codmes_mrm
LEFT JOIN v v1 ON v1.id_value = g.id_value AND v1.tip_doc = g.tip_doc
             AND v1.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(g.codmes_mrm, '%Y%m')), '%Y%m')
WHERE g.flg_scope_ree = 1
