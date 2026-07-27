-- ============================================================================
-- 40. DRIVERS - tipo de ingreso y cuenta sueldo
--   tipo_ingreso: periodo = codmes_mrm. Honesta: informado en t0-1 (H64).
--   flg_cs      : codmes = codmes_mrm - 1 por calendario.
--   Emite las DOS variantes de sit_lab_cs porque la decision no esta tomada:
--     _4v  como el build vigente        (Query_PO_calib#L332-337)
--     _5v  como el Recibido que lo especifica (Query Tipo Ingreso - CS#L11-17)
--   H28 midio que MIX_CS y MIX_NO_CS tienen bad-rate distinto los 4 anios
--   maduros. Emitir las dos cuesta lo mismo y evita reconstruir para decidir.
--   ctrl_fuente_nueva marca el regimen de 202604+ (SUSALUD, INFERIDO_IND_MVP).
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_40_drivers AS
WITH po AS (
  SELECT DISTINCT codmes_mrm, tip_doc, id_value
  FROM disc_model_owner.ds_stk_ree_pp_10_po
),
cls AS (
  SELECT tip_doc, id_value, codmes, sit_lab, fuente, tipo_ingreso
  FROM (
    SELECT
      CAST(a.tip_doc AS VARCHAR)   AS tip_doc,
      SUBSTR(a.subject_id, 3)      AS id_value,
      CAST(a.periodo AS VARCHAR)   AS codmes,
      a.sit_lab,
      a.fuente,
      CASE
        WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'DEPENDIENTE'
        WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'MIXTO'
        WHEN a.sit_lab = 'MIXTO' THEN 'MIXTO'
        ELSE 'INDEPENDIENTE'
      END                          AS tipo_ingreso,
      ROW_NUMBER() OVER (
        PARTITION BY SUBSTR(a.subject_id, 3), a.periodo, CAST(a.tip_doc AS VARCHAR)
        ORDER BY a.p_fecinformacion DESC, a.subject_id ASC) AS rn
    FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir a
    INNER JOIN po b
      ON CAST(a.periodo AS VARCHAR) = b.codmes_mrm
     AND SUBSTR(a.subject_id, 3) = b.id_value
    WHERE CAST(a.numcarga AS INT) = 1
  ) r
  WHERE rn = 1
),
cs AS (
  SELECT
    CAST(codmes AS VARCHAR)                          AS codmes,
    CAST(key_value AS VARCHAR)                       AS id_value,
    CAST(tipdoc AS VARCHAR)                          AS tip_doc,
    MAX(CAST(flg_cs_riesgos AS INTEGER))             AS flg_cs
  FROM e_perm_aws.t_rsk_cta_sueldo
  GROUP BY 1, 2, 3
)
SELECT
  po.codmes_mrm,
  po.tip_doc,
  po.id_value,
  COALESCE(c.tipo_ingreso, 'INDEPENDIENTE')                                   AS tipo_ingreso,
  CASE WHEN COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') = 'DEPENDIENTE'
       THEN 'DEP' ELSE 'NO DEP' END                                           AS tipo_ingreso_dep,
  COALESCE(s.flg_cs, 0)                                                       AS flg_cs,
  CASE
    WHEN COALESCE(c.tipo_ingreso,'INDEPENDIENTE') = 'DEPENDIENTE' AND COALESCE(s.flg_cs,0) = 1 THEN 'DEP_CS'
    WHEN COALESCE(c.tipo_ingreso,'INDEPENDIENTE') = 'DEPENDIENTE' AND COALESCE(s.flg_cs,0) = 0 THEN 'DEP_NO_CS'
    WHEN COALESCE(c.tipo_ingreso,'INDEPENDIENTE') = 'MIXTO'                                    THEN 'MIXTO'
    ELSE 'INDEPENDIENTE'
  END                                                                         AS sit_lab_cs_4v,
  CASE
    WHEN COALESCE(c.tipo_ingreso,'INDEPENDIENTE') = 'DEPENDIENTE' AND COALESCE(s.flg_cs,0) = 1 THEN 'DEP_CS'
    WHEN COALESCE(c.tipo_ingreso,'INDEPENDIENTE') = 'DEPENDIENTE' AND COALESCE(s.flg_cs,0) = 0 THEN 'DEP_NO_CS'
    WHEN COALESCE(c.tipo_ingreso,'INDEPENDIENTE') = 'MIXTO'       AND COALESCE(s.flg_cs,0) = 1 THEN 'MIX_CS'
    WHEN COALESCE(c.tipo_ingreso,'INDEPENDIENTE') = 'MIXTO'       AND COALESCE(s.flg_cs,0) = 0 THEN 'MIX_NO_CS'
    ELSE 'IND'
  END                                                                         AS sit_lab_cs_5v,
  CAST(CASE WHEN c.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER)             AS falla_sin_tipo_ingreso,
  CAST(CASE WHEN s.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER)             AS falla_sin_cta_sueldo,
  CAST(CASE WHEN c.fuente IN ('SUSALUD','INFERIDO_IND_MVP') THEN 1 ELSE 0 END AS INTEGER) AS ctrl_fuente_nueva
FROM po
LEFT JOIN cls c
       ON c.id_value = po.id_value AND c.tip_doc = po.tip_doc AND c.codmes = po.codmes_mrm
LEFT JOIN cs s
       ON s.id_value = po.id_value AND s.tip_doc = po.tip_doc
      AND s.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(po.codmes_mrm, '%Y%m')), '%Y%m')
