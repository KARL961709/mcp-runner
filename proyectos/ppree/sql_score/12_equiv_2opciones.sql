-- ============================================================================
-- 12. EQUIVALENCIA contra el pipeline de calibracion, las dos opciones.
--   Recorta el scoreo del stock a la MISMA poblacion del fit y contrasta.
--   El recorte son TRES condiciones: flg_scope_ree es eje aparte y no entra al
--   gate de flg_clean (70_cal.sql, A36), asi que se pide explicito.
--   El join va c.codmes_scr = s.codmes: es el ancla +1 con la que 50_pd cruzo.
--
--   ESPERADO en la fila TOTAL, calculado en 16_genera_sql_scoring.py sobre
--   master_ree_20261028 (ventana 202212-202509):
--     n            51,181
--     pd_raw        25.6005 pct
--     cal_v2         5.0566 pct
--     pit_v1         5.0566 pct      pit_v2    5.0566 pct
--     final_v1       5.3756 pct      final_v2  5.7593 pct
--     pct_dep       30.28 pct        RD real   5.0566 pct
--   Si la fila TOTAL no reproduce esos seis niveles, el SQL no replica la
--   cadena y la tabla no se usa.
-- ============================================================================
SELECT COALESCE(c.codmes_mrm, 'TOTAL')                                         AS codmes_mrm,
       COUNT(*)                                                                AS n,
       SUM(CASE WHEN abs(s.probabilidad - c.pd_raw) < 1e-12 THEN 1 ELSE 0 END) AS n_pd_raw_identica,
       ROUND(100.0 * AVG(s.probabilidad), 4)                                   AS pd_raw_pct,
       ROUND(100.0 * AVG(CAST(c.target_12m_60 AS DOUBLE)), 4)                  AS rd12_pct,
       ROUND(100.0 * AVG(s.prob_modelo_cal_v2), 4)                             AS cal_v2_pct,
       ROUND(100.0 * AVG(s.prob_modelo_pit_v1), 4)                             AS pit_v1_pct,
       ROUND(100.0 * AVG(s.prob_modelo_pit_v2), 4)                             AS pit_v2_pct,
       ROUND(100.0 * AVG(s.prob_modelo_final_v1), 4)                           AS final_v1_pct,
       ROUND(100.0 * AVG(s.prob_modelo_final_v2), 4)                           AS final_v2_pct,
       ROUND(100.0 * AVG(CASE WHEN s.trf_tipo_ingreso_dep = 'DEP' THEN 1.0 ELSE 0.0 END), 2) AS pct_dep,
       SUM(CASE WHEN s.trf_tipo_ingreso_dep <> c.tipo_ingreso_dep THEN 1 ELSE 0 END) AS n_segmento_distinto
FROM disc_model_owner.scr_stk_ree_pp_cal_2opc_v0 s
JOIN disc_model_owner.ds_stk_ree_pp_cal c
  ON c.codmes_scr = s.codmes
 AND c.tip_doc    = s.tip_doc
 AND c.id_value   = s.key_value
WHERE c.flg_calib     = 1
  AND c.flg_clean     = 1
  AND c.flg_scope_ree = 1
  AND c.codmes_mrm BETWEEN '202212' AND '202509'
GROUP BY GROUPING SETS ((c.codmes_mrm), ())
ORDER BY 1
