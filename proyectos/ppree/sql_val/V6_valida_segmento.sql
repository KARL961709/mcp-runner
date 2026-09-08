-- ============================================================================
-- V6. VALIDA que la CTE de segmento (cls_ing) ejecuta y da cobertura sana
--   Es la MISMA logica del inference.sql. Reporta DEP / NO DEP por periodo
--   reciente. Confirma ejecucion + %DEP estable (no valida contra la vigente
--   porque la poblacion del ds difiere de v5; la logica es byte-identica a 71).
-- ============================================================================
WITH cls_ing AS (
  SELECT substr(subject_id, 3)     AS id_value,
         cast(tip_doc as varchar)  AS tip_doc,
         cast(periodo as varchar)  AS codmes_mrm,
         CASE WHEN max(CASE WHEN sit_lab = 'DEPENDIENTE'
                             AND fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP')
                            THEN 1 ELSE 0 END) = 1
              THEN 'DEP' ELSE 'NO DEP' END AS tipo_ingreso_dep
    FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
   WHERE cast(numcarga as int) = 1
     AND cast(periodo as varchar) >= '202312'
   GROUP BY 1, 2, 3)
SELECT codmes_mrm,
       count(*)                                                           AS n_personas,
       sum(CASE WHEN tipo_ingreso_dep = 'DEP' THEN 1 ELSE 0 END)          AS n_dep,
       round(100.0 * avg(CASE WHEN tipo_ingreso_dep = 'DEP'
                              THEN 1.0 ELSE 0.0 END), 2)                  AS pct_dep
  FROM cls_ing
 WHERE codmes_mrm >= '202603'
 GROUP BY 1
 ORDER BY 1
