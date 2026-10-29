-- ============================================================================
-- v42. QA FINA del CTAS: tramo por tramo de score, no solo la media.
--
--   GENERADA por 30_genera_sql_final.py en la misma corrida que el CTAS.
--
--   POR QUE NO ALCANZA v40. Compara MEDIAS. Un nodo de la isotonica transcrito
--   de mas hacia arriba y otro hacia abajo se cancelan en el promedio global y
--   la QA pasa en verde con la escalera rota. Aca el score se corta en 10
--   tramos por celda con CORTES FIJOS -- no cuantiles, que podrian partir
--   distinto en cada motor por empates -- y cada tramo se compara contra lo que
--   Python calculo, embebido en la tabla ref.
--
--   Se comparan TRES capas, no una: el calibrador solo (isotonica), y las dos
--   PD finales. Si falla solo la primera, el defecto esta en los nodos. Si
--   fallan las tres por igual, esta en delta, escala o macro.
--
--   TOLERANCIA: dif_n = 0 exacto, y |dif| <= 1e-6 en las tres PD. Por encima de
--   eso el SQL no reproduce al pipeline y la tabla no se usa.
--
--   Ventana y poblacion identicas a las del fit: 202301-202509,
--   flg_calib = 1, flg_clean = 1, perimetro reenganche. n total 49,430.
-- ============================================================================
WITH ref AS (
  SELECT * FROM (VALUES
    ('DEP', 0, 0.0000000000, 0.0320997348, 1525, 0.0021517620, 0.0014212127, 0.0019820489, 0.0026229508),
    ('DEP', 1, 0.0320997348, 0.0529830158, 1525, 0.0063734325, 0.0040298674, 0.0060713856, 0.0078688525),
    ('DEP', 2, 0.0529830158, 0.0737401643, 1525, 0.0082949309, 0.0072270101, 0.0080770155, 0.0078688525),
    ('DEP', 3, 0.0737401643, 0.0974927280, 1524, 0.0114277145, 0.0111582113, 0.0113993098, 0.0118110236),
    ('DEP', 4, 0.0974927280, 0.1240421580, 1525, 0.0269673233, 0.0161169018, 0.0269629719, 0.0295081967),
    ('DEP', 5, 0.1240421580, 0.1588250526, 1525, 0.0291519435, 0.0227057652, 0.0293116709, 0.0288524590),
    ('DEP', 6, 0.1588250526, 0.2020416002, 1524, 0.0300976585, 0.0310217554, 0.0300707117, 0.0262467192),
    ('DEP', 7, 0.2020416002, 0.2635622840, 1525, 0.0412883545, 0.0443223067, 0.0415705249, 0.0419672131),
    ('DEP', 8, 0.2635622840, 0.3662579290, 1525, 0.0646922819, 0.0662017408, 0.0652553214, 0.0695081967),
    ('DEP', 9, 0.3662579290, 1.0000000000, 1525, 0.1067949430, 0.1230360024, 0.1065393477, 0.1009836066),
    ('NO DEP', 0, 0.0000000000, 0.0408749279, 3419, 0.0066972680, 0.0040765152, 0.0064676461, 0.0076045627),
    ('NO DEP', 1, 0.0408749279, 0.0684814794, 3418, 0.0112960680, 0.0100089095, 0.0112353673, 0.0111176126),
    ('NO DEP', 2, 0.0684814794, 0.0958307653, 3418, 0.0224637939, 0.0165751610, 0.0220182945, 0.0239906378),
    ('NO DEP', 3, 0.0958307653, 0.1266733310, 3418, 0.0306640550, 0.0235241796, 0.0298483627, 0.0286717379),
    ('NO DEP', 4, 0.1266733310, 0.1619198760, 3418, 0.0347650435, 0.0327249488, 0.0349703541, 0.0354008192),
    ('NO DEP', 5, 0.1619198760, 0.2048217186, 3418, 0.0480048981, 0.0442668320, 0.0485692532, 0.0506143944),
    ('NO DEP', 6, 0.2048217186, 0.2578234844, 3418, 0.0619053519, 0.0587515416, 0.0622096094, 0.0599765945),
    ('NO DEP', 7, 0.2578234844, 0.3303191542, 3418, 0.0808290153, 0.0795924954, 0.0816623005, 0.0798712697),
    ('NO DEP', 8, 0.3303191542, 0.4423645249, 3418, 0.1121837314, 0.1119452614, 0.1128114389, 0.1152720889),
    ('NO DEP', 9, 0.4423645249, 1.0000000000, 3419, 0.1654528726, 0.1927890220, 0.1644698257, 0.1617431998)
  ) AS t(celda, b, lo, hi, n_py, cal_py, v1_py, v2_py, rd_py)
),
s AS (
  SELECT CAST(codmes AS VARCHAR)               AS codmes,
         CAST(tip_doc AS VARCHAR)              AS tip_doc,
         CAST(key_value AS VARCHAR)            AS id_value,
         CAST(trf_tipo_ingreso_dep AS VARCHAR) AS celda,
         CAST(probabilidad AS DOUBLE)          AS p,
         CAST(trf_isotonica_v2 AS DOUBLE)      AS cal,
         CAST(prob_modelo_cal_v1 AS DOUBLE)    AS v1,
         CAST(prob_modelo_cal_v2 AS DOUBLE)    AS v2
  FROM disc_model_owner.scr_stk_ree_pp_cal_v1v2
),
g AS (
  SELECT CAST(codmes_mrm AS VARCHAR)           AS codmes,
         CAST(tip_doc AS VARCHAR)              AS tip_doc,
         CAST(id_value AS VARCHAR)             AS id_value,
         CAST(target_12m_60 AS DOUBLE)         AS y
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE flg_calib = 1
    AND flg_clean = 1
    AND (flg_scope_ree = 1 OR flg_ree_v4 = 1)
    AND codmes_mrm BETWEEN '202301' AND '202509'
),
j AS (
  SELECT s.celda, s.p, s.cal, s.v1, s.v2, g.y
  FROM g
  INNER JOIN s ON s.codmes = g.codmes AND s.tip_doc = g.tip_doc AND s.id_value = g.id_value
),
b AS (
  SELECT r.celda, r.b, r.n_py, r.cal_py, r.v1_py, r.v2_py, r.rd_py,
         COUNT(*)      AS n_sql,
         AVG(j.cal)    AS cal_sql,
         AVG(j.v1)     AS v1_sql,
         AVG(j.v2)     AS v2_sql,
         AVG(j.y)      AS rd_sql,
         MIN(j.v2)     AS v2_min,
         MAX(j.v2)     AS v2_max
  FROM j
  INNER JOIN ref r ON r.celda = j.celda AND j.p >= r.lo AND j.p < r.hi
  GROUP BY r.celda, r.b, r.n_py, r.cal_py, r.v1_py, r.v2_py, r.rd_py
)
SELECT celda,
       b                                              AS tramo,
       n_py,
       n_sql,
       n_sql - n_py                                   AS dif_n,
       ROUND(100.0 * rd_sql, 4)                       AS rd_pct,
       ROUND(100.0 * cal_sql, 6)                      AS isotonica_pct,
       ROUND(100.0 * v1_sql, 6)                       AS pd_v1_pct,
       ROUND(100.0 * v2_sql, 6)                       AS pd_v2_pct,
       ROUND(ABS(cal_sql - cal_py), 12)               AS dif_isotonica,
       ROUND(ABS(v1_sql - v1_py), 12)                 AS dif_v1,
       ROUND(ABS(v2_sql - v2_py), 12)                 AS dif_v2,
       ROUND(v2_min, 8)                               AS v2_min,
       ROUND(v2_max, 8)                               AS v2_max
FROM b
ORDER BY celda, b
