-- ============================================================================
-- E6. U6 (default silencioso de tipo_ingreso) y U5 (MIXTO sin abrir por CS)
--     pct_default MEDIDO POST-JOIN, por anio, sobre el perimetro reenganche.
-- ============================================================================
WITH ree AS (
  SELECT DISTINCT B.key_value, A.codmes_desembolso
  FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp A
  INNER JOIN e_perm_aws.t_mst_ctaibk_rsk B ON A.cif_key = B.cod_cuc
  WHERE A.subproducto = '1.REENGANCHE'
),
uni AS (
  SELECT
    CAST(u.codmes_mrm AS VARCHAR)  AS codmes_mrm,
    CAST(u.tip_doc AS VARCHAR)     AS tip_doc,
    CAST(u.id_value AS VARCHAR)    AS key_value,
    CASE WHEN u.flg_rfnc_12m = 1 OR u.flg_cstg_12m = 1 OR u.max_dm_12m > 60 THEN 1 ELSE 0 END AS y12
  FROM disc_model_owner.enr_ds_flg_compppibk_rsk u
  INNER JOIN ree r
    ON CAST(u.id_value AS VARCHAR) = CAST(r.key_value AS VARCHAR)
   AND CAST(u.codmes_mrm AS VARCHAR) = CAST(r.codmes_desembolso AS VARCHAR)
),
cls AS (
  SELECT tip_doc, key_value, codmes, tipo_ingreso_new
  FROM (
    SELECT
      CAST(a.tip_doc AS VARCHAR)                AS tip_doc,
      SUBSTR(a.subject_id, 3)                   AS key_value,
      CAST(a.periodo AS VARCHAR)                AS codmes,
      CASE
        WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'DEPENDIENTE'
        WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'MIXTO'
        WHEN a.sit_lab = 'MIXTO' THEN 'MIXTO'
        ELSE 'INDEPENDIENTE'
      END                                       AS tipo_ingreso_new,
      ROW_NUMBER() OVER (
        PARTITION BY SUBSTR(a.subject_id, 3), a.periodo, CAST(a.tip_doc AS VARCHAR)
        ORDER BY a.p_fecinformacion DESC)       AS rn
    FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir a
    INNER JOIN uni b
      ON CAST(a.periodo AS VARCHAR) = b.codmes_mrm
     AND SUBSTR(a.subject_id, 3) = b.key_value
    WHERE CAST(a.numcarga AS INT) = 1
  ) r WHERE rn = 1
)
SELECT
  SUBSTR(u.codmes_mrm, 1, 4)                                                        AS anio,
  COUNT(*)                                                                          AS n,
  SUM(CASE WHEN c.tipo_ingreso_new IS NULL THEN 1 ELSE 0 END)                       AS n_sin_fuente,
  ROUND(100.0 * SUM(CASE WHEN c.tipo_ingreso_new IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_default,
  SUM(CASE WHEN c.tipo_ingreso_new = 'DEPENDIENTE'   THEN 1 ELSE 0 END)             AS n_dep,
  SUM(CASE WHEN c.tipo_ingreso_new = 'MIXTO'         THEN 1 ELSE 0 END)             AS n_mixto,
  SUM(CASE WHEN c.tipo_ingreso_new = 'INDEPENDIENTE' THEN 1 ELSE 0 END)             AS n_indep,
  SUM(CASE WHEN cs.flg_cs_riesgos IS NOT NULL AND CAST(cs.flg_cs_riesgos AS INT) = 1 AND c.tipo_ingreso_new = 'MIXTO' THEN 1 ELSE 0 END) AS n_mixto_cs,
  ROUND(AVG(CASE WHEN c.tipo_ingreso_new = 'MIXTO' AND COALESCE(CAST(cs.flg_cs_riesgos AS INT), 0) = 1 THEN CAST(u.y12 AS DOUBLE) END), 4) AS rd_mixto_cs,
  ROUND(AVG(CASE WHEN c.tipo_ingreso_new = 'MIXTO' AND COALESCE(CAST(cs.flg_cs_riesgos AS INT), 0) = 0 THEN CAST(u.y12 AS DOUBLE) END), 4) AS rd_mixto_no_cs,
  ROUND(AVG(CAST(u.y12 AS DOUBLE)), 4)                                              AS rd_total
FROM uni u
LEFT JOIN cls c
  ON u.key_value = c.key_value AND u.codmes_mrm = c.codmes AND u.tip_doc = c.tip_doc
LEFT JOIN e_perm_aws.t_rsk_cta_sueldo cs
  ON CAST(u.tip_doc AS INTEGER) = CAST(cs.tipdoc AS INTEGER)
 AND u.key_value = cs.key_value
 AND DATE_FORMAT(DATE_PARSE(u.codmes_mrm, '%Y%m') - INTERVAL '1' MONTH, '%Y%m') = cs.codmes
GROUP BY 1
ORDER BY 1
