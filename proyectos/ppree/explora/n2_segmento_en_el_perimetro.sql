-- ============================================================================
-- N2. El quiebre de 202604 MEDIDO EN EL PERIMETRO QUE SE SCOREA, no en los 32M
--     de la fuente. n1 midio la fuente completa: ese fue su defecto.
--     Dos anclas enfrentadas:
--       CAL  periodo = codmes_mrm       (Query_PO_calib#L302)
--       SCR  periodo = codmes del score (22_scoring_ree_v3.sql#L55)
--     Con v4.codmes = codmes_mrm + 1, difieren en un mes.
-- ============================================================================
WITH cls AS (
  SELECT CAST(periodo AS VARCHAR) AS periodo, SUBSTR(subject_id, 3) AS key_value,
    CASE
      WHEN sit_lab = 'DEPENDIENTE' AND fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'DEPENDIENTE'
      WHEN sit_lab = 'DEPENDIENTE' AND fuente IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'MIXTO'
      WHEN sit_lab = 'MIXTO' THEN 'MIXTO'
      ELSE 'INDEPENDIENTE'
    END AS tipo_ingreso,
    ROW_NUMBER() OVER (PARTITION BY SUBSTR(subject_id, 3), periodo ORDER BY p_fecinformacion DESC) AS rn
  FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
  WHERE CAST(periodo AS INT) BETWEEN 202512 AND 202606 AND CAST(numcarga AS INT) = 1
),
c AS (SELECT periodo, key_value, tipo_ingreso FROM cls WHERE rn = 1),
scr AS (
  SELECT CAST(codmes AS VARCHAR) AS codmes, CAST(key_value AS VARCHAR) AS key_value,
         CAST(flg_reenganche AS INTEGER) AS flg_ree
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
  WHERE CAST(codmes AS INT) BETWEEN 202601 AND 202605
)
SELECT
  s.codmes                                                                        AS codmes_score,
  COUNT(*)                                                                        AS n_stock,
  SUM(s.flg_ree)                                                                  AS n_ree,
  SUM(CASE WHEN cal.tipo_ingreso = 'DEPENDIENTE'   THEN 1 ELSE 0 END)             AS cal_dep,
  SUM(CASE WHEN cal.tipo_ingreso = 'MIXTO'         THEN 1 ELSE 0 END)             AS cal_mixto,
  SUM(CASE WHEN cal.tipo_ingreso = 'INDEPENDIENTE' THEN 1 ELSE 0 END)             AS cal_indep,
  SUM(CASE WHEN cal.tipo_ingreso IS NULL THEN 1 ELSE 0 END)                       AS cal_sin_dato,
  SUM(CASE WHEN sc.tipo_ingreso = 'DEPENDIENTE'    THEN 1 ELSE 0 END)             AS scr_dep,
  SUM(CASE WHEN sc.tipo_ingreso = 'MIXTO'          THEN 1 ELSE 0 END)             AS scr_mixto,
  SUM(CASE WHEN sc.tipo_ingreso = 'INDEPENDIENTE'  THEN 1 ELSE 0 END)             AS scr_indep,
  SUM(CASE WHEN cal.tipo_ingreso <> sc.tipo_ingreso THEN 1 ELSE 0 END)            AS n_difieren_anclas
FROM scr s
LEFT JOIN c cal
  ON cal.key_value = s.key_value
 AND cal.periodo = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(s.codmes, '%Y%m')), '%Y%m')
LEFT JOIN c sc
  ON sc.key_value = s.key_value
 AND sc.periodo = s.codmes
GROUP BY 1
ORDER BY 1
