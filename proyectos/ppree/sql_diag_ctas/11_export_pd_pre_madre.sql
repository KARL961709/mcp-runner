-- ============================================================================
-- 11. PARQUET PD PRE / POST Y SEGMENTO POR ALTA REENGANCHE - SOLO FUENTES MADRE
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_px_pdpre_madre
WITH (format = 'PARQUET', write_compression = 'SNAPPY',
      external_location = '<S3_DATOS>/pd_pre_madre/') AS
WITH mar AS (
  SELECT DISTINCT
    CAST(b.key_value AS VARCHAR)         AS key_value,
    CAST(a.codmes_desembolso AS VARCHAR) AS d
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp a
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk b
    ON CAST(a.cif_key AS VARCHAR) = CAST(b.cod_cuc AS VARCHAR)
  WHERE a.subproducto = '1.REENGANCHE'
    AND LENGTH(CAST(b.key_value AS VARCHAR)) = 64
    AND CAST(a.codmes_desembolso AS VARCHAR) >= '202312'
),
v AS (
  SELECT CAST(key_value AS VARCHAR) AS key_value, CAST(codmes AS VARCHAR) AS codmes,
         MAX(pd_comppp_reen_itc) AS pd
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
  GROUP BY 1, 2
),
seg AS (
  SELECT SUBSTR(subject_id, 3) AS key_value, CAST(periodo AS VARCHAR) AS periodo,
         CASE WHEN MAX(CASE WHEN sit_lab = 'DEPENDIENTE'
                             AND fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP')
                            THEN 1 ELSE 0 END) = 1
              THEN 'DEP' ELSE 'NO DEP' END AS tipo_ingreso_dep
  FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
  WHERE CAST(numcarga AS INT) = 1
    AND CAST(periodo AS VARCHAR) >= '202311'
  GROUP BY 1, 2
)
SELECT
  m.d             AS codmes,
  m.key_value,
  v0.pd           AS pd_pre_d,
  v1.pd           AS pd_pre_dm1,
  v2.pd           AS pd_post_d1,
  s1.tipo_ingreso_dep AS seg_dm1,
  s0.tipo_ingreso_dep AS seg_d
FROM mar m
LEFT JOIN v v0 ON v0.key_value = m.key_value AND v0.codmes = m.d
LEFT JOIN v v1 ON v1.key_value = m.key_value
             AND v1.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(m.d, '%Y%m')), '%Y%m')
LEFT JOIN v v2 ON v2.key_value = m.key_value
             AND v2.codmes = DATE_FORMAT(DATE_ADD('month',  1, DATE_PARSE(m.d, '%Y%m')), '%Y%m')
LEFT JOIN seg s1 ON s1.key_value = m.key_value
             AND s1.periodo = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(m.d, '%Y%m')), '%Y%m')
LEFT JOIN seg s0 ON s0.key_value = m.key_value
             AND s0.periodo = m.d
