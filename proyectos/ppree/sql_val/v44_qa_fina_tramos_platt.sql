-- ============================================================================
-- v44. QA FINA del CTAS: tramo por tramo de score, no solo la media.
--
--   GENERADA por 31_genera_sql_v2platt.py en la misma corrida que el CTAS.
--
--   POR QUE NO ALCANZA v43. Compara MEDIAS. Un error de signo o de escala en
--   el logit de Platt puede subir un tramo y bajar otro, cancelarse en el
--   promedio global y dejar la QA en verde con la curva torcida. Aca el score
--   se corta en 10
--   tramos por celda con CORTES FIJOS -- no cuantiles, que podrian partir
--   distinto en cada motor por empates -- y cada tramo se compara contra lo que
--   Python calculo, embebido en la tabla ref.
--
--   Se comparan TRES capas, no una: el calibrador solo (Platt), y las dos PD
--   finales. Si falla solo la primera, el defecto esta en (a, b) o en el logit.
--   Si fallan las tres por igual, esta en delta, rho, el piso o la macro.
--
--   V1 se evalua sobre la ventana de V2 para que las tres capas miren la misma
--   poblacion. Su EC ahi NO cierra y no debe cerrar: V1 esta anclado sobre
--   202301-202509, que incluye HIST_PROXY.
--
--   TOLERANCIA: dif_n = 0 exacto, y |dif| <= 1e-6 en las tres PD. Por encima de
--   eso el SQL no reproduce al pipeline y la tabla no se usa.
--
--   Ventana y poblacion identicas a las del fit de V2: 202401-202509,
--   flg_calib = 1, flg_clean = 1, perimetro reenganche. n total 30,528.
-- ============================================================================
WITH ref AS (
  SELECT * FROM (VALUES
    ('DEP', 0, 0.0000000000, 0.0289371802, 1137, 0.0033278774, 0.0010296289, 0.0028366619, 0.0035180299),
    ('DEP', 1, 0.0289371802, 0.0479427150, 1136, 0.0065286256, 0.0028956335, 0.0057996051, 0.0052816901),
    ('DEP', 2, 0.0479427150, 0.0669962708, 1137, 0.0094197431, 0.0051314449, 0.0085072174, 0.0070360598),
    ('DEP', 3, 0.0669962708, 0.0898144010, 1136, 0.0125614005, 0.0079589416, 0.0114903100, 0.0035211268),
    ('DEP', 4, 0.0898144010, 0.1155874110, 1136, 0.0162073450, 0.0115574082, 0.0150321411, 0.0211267606),
    ('DEP', 5, 0.1155874110, 0.1486407600, 1137, 0.0206393061, 0.0163537371, 0.0193178682, 0.0299032542),
    ('DEP', 6, 0.1486407600, 0.1907206246, 1136, 0.0266087788, 0.0234057151, 0.0253729849, 0.0228873239),
    ('DEP', 7, 0.1907206246, 0.2501731140, 1137, 0.0351179431, 0.0339095485, 0.0338889313, 0.0325417766),
    ('DEP', 8, 0.2501731140, 0.3520593894, 1136, 0.0491237632, 0.0513845411, 0.0481361781, 0.0616197183),
    ('DEP', 9, 0.3520593894, 1.0000000000, 1137, 0.1020010871, 0.1017100237, 0.1033468963, 0.0941072999),
    ('NO DEP', 0, 0.0000000000, 0.0313389752, 1917, 0.0057172064, 0.0025716437, 0.0052158679, 0.0046948357),
    ('NO DEP', 1, 0.0313389752, 0.0511046800, 1916, 0.0102301242, 0.0058192147, 0.0095988294, 0.0088726514),
    ('NO DEP', 2, 0.0511046800, 0.0724603930, 1916, 0.0140421711, 0.0091987819, 0.0133967910, 0.0125260960),
    ('NO DEP', 3, 0.0724603930, 0.0944359900, 1916, 0.0180461595, 0.0130715862, 0.0174282417, 0.0172233820),
    ('NO DEP', 4, 0.0944359900, 0.1202983700, 1916, 0.0220698128, 0.0172774716, 0.0215033707, 0.0213987474),
    ('NO DEP', 5, 0.1202983700, 0.1522489520, 1917, 0.0270688425, 0.0226852645, 0.0266838807, 0.0245174752),
    ('NO DEP', 6, 0.1522489520, 0.1941635136, 1916, 0.0332678004, 0.0300626680, 0.0331284088, 0.0302713987),
    ('NO DEP', 7, 0.1941635136, 0.2541448986, 1916, 0.0419465389, 0.0410692202, 0.0423602412, 0.0438413361),
    ('NO DEP', 8, 0.2541448986, 0.3536918458, 1916, 0.0561643376, 0.0590885917, 0.0574409245, 0.0657620042),
    ('NO DEP', 9, 0.3536918458, 1.0000000000, 1917, 0.1022747381, 0.1160569808, 0.1074651452, 0.1017214397)
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
    AND codmes_mrm BETWEEN '202401' AND '202509'
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
       ROUND(100.0 * cal_sql, 6)                      AS platt_pct,
       ROUND(100.0 * v1_sql, 6)                       AS pd_v1_pct,
       ROUND(100.0 * v2_sql, 6)                       AS pd_v2_pct,
       ROUND(ABS(cal_sql - cal_py), 12)               AS dif_platt,
       ROUND(ABS(v1_sql - v1_py), 12)                 AS dif_v1,
       ROUND(ABS(v2_sql - v2_py), 12)                 AS dif_v2,
       ROUND(v2_min, 8)                               AS v2_min,
       ROUND(v2_max, 8)                               AS v2_max
FROM b
ORDER BY celda, b
