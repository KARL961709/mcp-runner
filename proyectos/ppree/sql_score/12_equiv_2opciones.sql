-- ============================================================================
-- 12. SUPERADO por v30. No valida nada hasta que se recalibre.
--
--   Corrio y dio n_pd_raw_identica = 0 en los 34 meses, con
--   n_segmento_distinto = 0. Eso NO era un bug: v30 probo que
--     ds_stk_ree_pp_cal HOY  ancla pd_raw en codmes_mrm  (49,430 de 49,430 identicas)
--     el parquet del fit     anclaba en codmes_scr       (cohorte M = fuente en M+1)
--   La tabla del banco se reconstruyo despues de exportarse el parquet, asi que
--   ya no existe en el banco una poblacion que represente la calibracion.
--
--   Por eso este archivo no se puede arreglar cambiando el join: lo que falta es
--   recalibrar sobre el ancla nueva. Secuencia: correr 96_export_master_2609,
--   re-correr la cadena, y regenerar 10 con codmes_drv = codmes.
--
--   Queda esta consulta, que mide la poblacion VIVA y sirve de linea base para
--   el proximo round: cuantas cohortes y cuantos malos hay con el ancla nueva.
-- ============================================================================
SELECT COALESCE(codmes_mrm, 'TOTAL')                          AS codmes_mrm,
       COUNT(*)                                               AS n,
       SUM(CAST(target_12m_60 AS BIGINT))                      AS malos,
       ROUND(100.0 * AVG(CAST(target_12m_60 AS DOUBLE)), 4)    AS rd12_pct,
       ROUND(100.0 * AVG(pd_raw), 4)                           AS pd_raw_pct,
       ROUND(100.0 * AVG(CASE WHEN tipo_ingreso_dep = 'DEP' THEN 1.0 ELSE 0.0 END), 2) AS pct_dep,
       SUM(CASE WHEN falla_madurez_12 = 1 THEN 1 ELSE 0 END)   AS n_inmaduro_12m
FROM disc_model_owner.ds_stk_ree_pp_cal
WHERE flg_clean = 1
  AND flg_scope_ree = 1
  AND pd_raw IS NOT NULL
  AND codmes_mrm >= '202301'
GROUP BY GROUPING SETS ((codmes_mrm), ())
ORDER BY 1
