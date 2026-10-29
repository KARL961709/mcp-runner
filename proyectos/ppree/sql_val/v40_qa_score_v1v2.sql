-- ============================================================================
-- v40. QA del CTAS 20_score_v1v2_final. Reproduce el pipeline sobre el fit
--
--   GENERADA por 30_genera_sql_final.py en la MISMA corrida que el CTAS. No se
--   edita a mano: la ventana y las anclas se inyectan desde la config y el
--   pipeline, asi que no pueden quedar desincronizadas del build (R12).
--
--   El generador ya probo que los COEFICIENTES reproducen el pipeline en Python.
--   Lo que esa prueba NO cubre es la aritmetica del SQL: la macro recalculada
--   desde porc_ipc, la interpolacion de la isotonica por nodos, los clips y el
--   join del segmento. Eso se verifica aca contra numeros conocidos.
--
--   ANCLAS del pipeline sobre flg_calib = 1 AND flg_clean = 1, 202301-202509
--   (n = 49,430, malos = 2462). Las dos opciones anclan a la MISMA LRA:
--     global   4.9808 pct
--     DEP      3.2726 pct
--     NO DEP   5.7428 pct
--   La RD realizada es ese mismo 4.9808 pct -- el ancla es exacta por
--   construccion, asi que una desviacion aca es defecto del SQL, no del modelo.
--
--   EXCEPCION declarada a R12: la QA lee ds_stk_ree_pp_cal, que este build no
--   escribe. Es la tabla gobernada de Fase 1, usada como referencia y no como
--   salida. Ninguna otra tabla ajena entra.
--
--   Se reporta MAGNITUD, no OK/FALLA. Tolerancia 0.5 pct relativo por ancla.
--   Por encima, mirar el rango de f_t antes que el calibrador: es donde el SQL
--   (que compone la interanual desde porc_ipc) y Python pueden separarse.
-- ============================================================================
WITH s AS (
  SELECT CAST(codmes AS VARCHAR)               AS codmes,
         CAST(tip_doc AS VARCHAR)              AS tip_doc,
         CAST(key_value AS VARCHAR)            AS id_value,
         CAST(trf_tipo_ingreso_dep AS VARCHAR) AS celda,
         CAST(prob_modelo_cal_v1 AS DOUBLE)    AS pd_v1,
         CAST(prob_modelo_cal_v2 AS DOUBLE)    AS pd_v2,
         CAST(trf_f_t_v1 AS DOUBLE)            AS ft_v1,
         CAST(trf_f_t_v2 AS DOUBLE)            AS ft_v2
  FROM disc_model_owner.scr_stk_ree_pp_cal_v1v2
),
g AS (
  SELECT CAST(codmes_mrm AS VARCHAR)           AS codmes,
         CAST(tip_doc AS VARCHAR)              AS tip_doc,
         CAST(id_value AS VARCHAR)             AS id_value,
         CAST(tipo_ingreso_dep AS VARCHAR)     AS celda_master,
         CAST(target_12m_60 AS DOUBLE)         AS y
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE flg_calib = 1
    AND flg_clean = 1
    AND (flg_scope_ree = 1 OR flg_ree_v4 = 1)
    AND codmes_mrm BETWEEN '202301' AND '202509'
),
j AS (
  SELECT g.celda_master, g.y, s.pd_v1, s.pd_v2, s.ft_v1, s.ft_v2,
         CASE WHEN s.celda = g.celda_master THEN 1 ELSE 0 END AS celda_ok,
         CASE WHEN s.id_value IS NULL THEN 1 ELSE 0 END       AS no_cruza
  FROM g
  LEFT JOIN s ON s.codmes = g.codmes AND s.tip_doc = g.tip_doc AND s.id_value = g.id_value
)
SELECT COALESCE(celda_master, 'GLOBAL')                                  AS celda,
       COUNT(*)                                                          AS n,
       SUM(no_cruza)                                                     AS n_sin_cruce,
       SUM(CASE WHEN no_cruza = 0 THEN celda_ok ELSE 0 END)              AS n_celda_ok,
       ROUND(100.0 * AVG(y), 4)                                          AS rd_observada,
       ROUND(100.0 * AVG(pd_v1), 4)                                      AS pd_v1,
       ROUND(100.0 * AVG(pd_v2), 4)                                      AS pd_v2,
       ROUND(100.0 * (AVG(pd_v1) / NULLIF(AVG(y), 0) - 1.0), 4)          AS ec_v1_pct,
       ROUND(100.0 * (AVG(pd_v2) / NULLIF(AVG(y), 0) - 1.0), 4)          AS ec_v2_pct,
       ROUND(MIN(ft_v1), 6)                                              AS ft_v1_min,
       ROUND(MAX(ft_v1), 6)                                              AS ft_v1_max,
       ROUND(MIN(ft_v2), 6)                                              AS ft_v2_min,
       ROUND(MAX(ft_v2), 6)                                              AS ft_v2_max
FROM j
GROUP BY GROUPING SETS ((celda_master), ())
ORDER BY 1
