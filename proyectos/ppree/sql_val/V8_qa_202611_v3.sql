-- ============================================================================
-- V8. QA de scr_stk_ree_pp_cal_202611_v3 contra su fuente. READ-ONLY, un statement.
--   Devuelve una fila por chequeo con n y magnitud, no solo veredicto.
--   G1 grano y conteo contra el _v2        G5 nivel de PD por celda
--   G2 nulos de cada columna de PD         G6 reparto por grupo de apetito
--   G3 macro: f_t vivo y congelado         G7 monotonia del grupo en PD
--   G4 piso y techo mordiendo
-- ============================================================================
WITH v2 AS (
  SELECT COUNT(*) AS n2,
         COUNT(DISTINCT CONCAT(CAST(cod_mes AS VARCHAR), '|', CAST(cod_tip_doc AS VARCHAR),
                               '|', CAST(key_value AS VARCHAR))) AS k2
  FROM disc_model_owner.scr_stk_ree_pp_cal_202611_v2
),
v3 AS (
  SELECT COUNT(*) AS n3,
         COUNT(DISTINCT CONCAT(CAST(cod_mes AS VARCHAR), '|', CAST(cod_tip_doc AS VARCHAR),
                               '|', CAST(key_value AS VARCHAR))) AS k3,
         COUNT(prob_modelo_cal) AS n_viva,
         COUNT(prob_modelo_cal_smacro) AS n_smac,
         COUNT(prob_modelo_cal_freeze) AS n_frz,
         SUM(CASE WHEN prob_modelo_cal_freeze <= 0.0005 THEN 1 ELSE 0 END) AS n_piso,
         SUM(CASE WHEN prob_modelo_cal_freeze >= 0.9999 THEN 1 ELSE 0 END) AS n_techo,
         AVG(prob_modelo_cal_freeze) AS pd_frz,
         AVG(prob_modelo_cal_smacro) AS pd_smac,
         MIN(trf_macro01_freeze) AS ftz_min, MAX(trf_macro01_freeze) AS ftz_max,
         MIN(trf_macro02_freeze) AS ma3z_min, MAX(trf_macro02_freeze) AS ma3z_max,
         COUNT(trf_macro01) AS n_ftv
  FROM disc_model_owner.scr_stk_ree_pp_cal_202611_v3
)
SELECT 'G1 grano' AS gate, CAST(n3 AS VARCHAR) AS n,
       CONCAT('v2 ', CAST(n2 AS VARCHAR), ' filas / ', CAST(k2 AS VARCHAR), ' llaves  v3 ',
              CAST(n3 AS VARCHAR), ' / ', CAST(k3 AS VARCHAR)) AS magnitud,
       CASE WHEN n3 = n2 AND k3 = k2 THEN 'PASS' ELSE 'FAIL' END AS veredicto
FROM v2 CROSS JOIN v3
UNION ALL
SELECT 'G2 nulos de PD', CAST(n3 AS VARCHAR),
       CONCAT('viva ', CAST(n_viva AS VARCHAR), '  smacro ', CAST(n_smac AS VARCHAR),
              '  freeze ', CAST(n_frz AS VARCHAR)),
       CASE WHEN n_frz = n3 AND n_smac = n3 THEN 'PASS' ELSE 'FAIL' END
FROM v3
UNION ALL
SELECT 'G3 macro congelada', CAST(n3 AS VARCHAR),
       CONCAT('f_t ', CAST(ROUND(ftz_min, 8) AS VARCHAR), ' a ',
              CAST(ROUND(ftz_max, 8) AS VARCHAR), '  MA3 ',
              CAST(ROUND(ma3z_min, 6) AS VARCHAR), ' a ', CAST(ROUND(ma3z_max, 6) AS VARCHAR)),
       CASE WHEN ftz_min = ftz_max AND ma3z_min = ma3z_max THEN 'PASS' ELSE 'FAIL' END
FROM v3
UNION ALL
SELECT 'G3b macro viva', CAST(n_ftv AS VARCHAR),
       CONCAT('filas con f_t vivo ', CAST(n_ftv AS VARCHAR), ' de ', CAST(n3 AS VARCHAR)),
       CASE WHEN n_ftv = 0 OR n_ftv = n3 THEN 'PASS' ELSE 'FAIL' END
FROM v3
UNION ALL
SELECT 'G4 piso y techo', CAST(n_piso + n_techo AS VARCHAR),
       CONCAT('piso ', CAST(n_piso AS VARCHAR), '  techo ', CAST(n_techo AS VARCHAR)),
       CASE WHEN n_techo = 0 THEN 'PASS' ELSE 'FAIL' END
FROM v3
UNION ALL
SELECT 'G5 nivel', CAST(n3 AS VARCHAR),
       CONCAT('PD freeze ', CAST(ROUND(100 * pd_frz, 4) AS VARCHAR),
              ' pct  PD sin macro ', CAST(ROUND(100 * pd_smac, 4) AS VARCHAR), ' pct'),
       CASE WHEN pd_frz > pd_smac THEN 'PASS' ELSE 'REVISAR' END
FROM v3
UNION ALL
SELECT CONCAT('G6 ', woe_trf_tipo_ingreso_dep), CAST(COUNT(*) AS VARCHAR),
       CONCAT('PD freeze ', CAST(ROUND(100 * AVG(prob_modelo_cal_freeze), 4) AS VARCHAR), ' pct'),
       'INFO'
FROM disc_model_owner.scr_stk_ree_pp_cal_202611_v3
GROUP BY woe_trf_tipo_ingreso_dep
UNION ALL
SELECT CONCAT('G7 ', grupo_calibracion), CAST(COUNT(*) AS VARCHAR),
       CONCAT('pct ', CAST(ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS VARCHAR),
              '  PD ', CAST(ROUND(100 * AVG(prob_modelo_cal_freeze), 4) AS VARCHAR),
              ' pct  score ', CAST(MIN(puntuacion_cal_freeze) AS VARCHAR), ' a ',
              CAST(MAX(puntuacion_cal_freeze) AS VARCHAR)),
       'INFO'
FROM disc_model_owner.scr_stk_ree_pp_cal_202611_v3
GROUP BY grupo_calibracion
ORDER BY 1