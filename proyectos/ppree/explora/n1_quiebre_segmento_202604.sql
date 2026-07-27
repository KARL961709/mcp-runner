-- ============================================================================
-- N1. QUIEBRE DEL DRIVER EN 202604. SUSALUD aparece en 202604 e
--     INFERIDO_IND_MVP en 202605, y los dos estan en la lista enumerada del
--     CASE. Cuanto del perimetro cambia de segmento por eso, mes a mes.
--     tipo_ingreso_dep es la segmentacion primaria del calibrador.
-- ============================================================================
WITH cls AS (
  SELECT
    CAST(a.periodo AS VARCHAR)  AS codmes,
    SUBSTR(a.subject_id, 3)     AS key_value,
    a.sit_lab,
    a.fuente,
    CASE
      WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'DEPENDIENTE'
      WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'MIXTO'
      WHEN a.sit_lab = 'MIXTO' THEN 'MIXTO'
      ELSE 'INDEPENDIENTE'
    END                         AS tipo_ingreso_vigente,
    CASE
      WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente NOT IN ('INFERIDO','EXPERIAN') THEN 'DEPENDIENTE'
      WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente IN ('INFERIDO','EXPERIAN') THEN 'MIXTO'
      WHEN a.sit_lab = 'MIXTO' THEN 'MIXTO'
      ELSE 'INDEPENDIENTE'
    END                         AS tipo_ingreso_sin_nuevas,
    ROW_NUMBER() OVER (PARTITION BY SUBSTR(a.subject_id, 3), a.periodo
                       ORDER BY a.p_fecinformacion DESC) AS rn
  FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir a
  WHERE CAST(a.periodo AS INT) BETWEEN 202601 AND 202606
    AND CAST(a.numcarga AS INT) = 1
)
SELECT
  codmes,
  COUNT(*)                                                                       AS n,
  SUM(CASE WHEN fuente = 'SUSALUD' THEN 1 ELSE 0 END)                            AS n_susalud,
  SUM(CASE WHEN fuente = 'INFERIDO_IND_MVP' THEN 1 ELSE 0 END)                   AS n_inferido_mvp,
  SUM(CASE WHEN tipo_ingreso_vigente <> tipo_ingreso_sin_nuevas THEN 1 ELSE 0 END) AS n_cambia_segmento,
  SUM(CASE WHEN tipo_ingreso_vigente = 'DEPENDIENTE' THEN 1 ELSE 0 END)          AS n_dep_vigente,
  SUM(CASE WHEN tipo_ingreso_sin_nuevas = 'DEPENDIENTE' THEN 1 ELSE 0 END)       AS n_dep_sin_nuevas
FROM cls
WHERE rn = 1
GROUP BY 1
ORDER BY 1
