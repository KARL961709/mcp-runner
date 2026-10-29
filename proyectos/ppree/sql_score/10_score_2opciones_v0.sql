-- ============================================================================
-- 10. PD calibrada del stock PP -- DOS OPCIONES en paralelo  (spec V0)
--
-- Formato calcado de 02_score_stock_pp.sql. TODO PARTE DE FUENTES MADRE:
--   score              disc_model_owner.scr_stk_ree_pp_cal_2023_202610 (prob_modelo)
--   situacion laboral  e_perm_aws.ds_rtd_rskvol_cas_ingr_ir   -> tipo_ingreso
--   cuenta sueldo      e_perm_aws.t_rsk_cta_sueldo            -> flg_cs
--   macro              e_perm_aws.t_mst_bcrp_rsk (porc_ipc)   -> f_t de las dos
--
-- porc_ipc es la variacion MENSUAL del IPC, no la interanual (v29: identica a
-- IPC_Lima_var_12m a 4.9e-11). De ahi:
--   v1  MA6 lag5 de porc_ipc directo, como el v5
--   v2  interanual COMPUESTA  (exp(sum(ln(1+x/100)))-1)*100 sobre 12 meses,
--       despues MA3 lag2. La composicion reproduce la y/y real a 0.0 en 78 meses.
--
-- codmes_drv = codmes - 1 es el mes de los drivers y del f_t, igual que el
-- vigente: es el rezago con el que la calibracion aprendio pd_raw(codmes)
-- contra driver(codmes-1).
--
-- Las dos opciones anclan la LRA del PERIMETRO REENGANCHE, no la del stock.
-- Sobre el stock completo el nivel queda corrido, y sirve para comparar v1 contra
-- v2 (mismo sesgo de nivel) y para aterrizar despues a altas por codmes_drv.
--
-- v1 = params v5 congelados + delta re-anclada al master nuevo + MoC desplegado
-- v2 = isotonica (56 y 82 nodos REALES del objeto ajustado) + macro ma3 lag2
--      + MoC por celda + piso Basilea 3bp
--
-- Verificado en 16_genera_sql_scoring.py contra el pipeline:
--   v1 pd_pit 0.0e+00   v2 pd_pit 0.0e+00   v2 pd_final 0.0e+00
-- ============================================================================
CREATE TABLE disc_model_owner.scr_stk_ree_pp_cal_2opc_v0
WITH (format = 'PARQUET', write_compression = 'SNAPPY') AS
WITH d AS (
  SELECT CAST(v.cod_mes AS VARCHAR) AS codmes,
         DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(CAST(v.cod_mes AS VARCHAR), '%Y%m')), '%Y%m') AS codmes_drv,
         CAST(v.cod_tip_doc AS VARCHAR) AS tip_doc,
         CAST(v.key_value AS VARCHAR) AS id_value,
         GREATEST(1e-9, LEAST(1.0 - 1e-9, AVG(v.prob_modelo))) AS p,
         MAX(v.puntuacion) AS puntuacion
  FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610 v
  WHERE v.prob_modelo IS NOT NULL
  GROUP BY CAST(v.cod_mes AS VARCHAR), CAST(v.cod_tip_doc AS VARCHAR), CAST(v.key_value AS VARCHAR)
),
spine AS (
  SELECT DISTINCT codmes_drv FROM d
),
ft1 AS (
  SELECT c.codmes_drv,
         GREATEST(-1.1308495594, LEAST(0.7656842282,
           (-1.6393937657 - sqrt(1.0 - 0.0380301160) * (-1.9001957962 + 0.6583423568 * AVG(m.porc_ipc)))
           / sqrt(0.0380301160))) AS f_t
  FROM spine c
  JOIN e_perm_aws.t_mst_bcrp_rsk m
    ON m.cod_mes BETWEEN DATE_FORMAT(DATE_ADD('month', -10, DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
                     AND DATE_FORMAT(DATE_ADD('month',  -5, DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
  WHERE m.porc_ipc IS NOT NULL
  GROUP BY c.codmes_drv
  HAVING COUNT(m.porc_ipc) = 6
),
yy AS (
  SELECT c.codmes_drv, t.k,
         (exp(SUM(ln(1.0 + m.porc_ipc / 100.0))) - 1.0) * 100.0 AS yy
  FROM spine c
  CROSS JOIN UNNEST(ARRAY[2, 3, 4]) AS t(k)
  JOIN e_perm_aws.t_mst_bcrp_rsk m
    ON m.cod_mes BETWEEN DATE_FORMAT(DATE_ADD('month', -(t.k + 11), DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
                     AND DATE_FORMAT(DATE_ADD('month', -t.k,        DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
  WHERE m.porc_ipc IS NOT NULL
  GROUP BY c.codmes_drv, t.k
  HAVING COUNT(m.porc_ipc) = 12
),
ft2 AS (
  SELECT codmes_drv,
         GREATEST(-0.1449929144, LEAST(0.2182222748,
           0.0518696720 * (AVG(yy) - 4.3327720459))) AS f_t
  FROM yy
  GROUP BY codmes_drv
  HAVING COUNT(yy) = 3
),
po AS (
  SELECT DISTINCT codmes_drv, tip_doc, id_value FROM d
),
cls AS (
  SELECT tip_doc, id_value, codmes, tipo_ingreso
  FROM (
    SELECT CAST(a.tip_doc AS VARCHAR) AS tip_doc,
           SUBSTR(a.subject_id, 3)    AS id_value,
           CAST(a.periodo AS VARCHAR) AS codmes,
           CASE
             WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'DEPENDIENTE'
             WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'MIXTO'
             WHEN a.sit_lab = 'MIXTO' THEN 'MIXTO'
             ELSE 'INDEPENDIENTE'
           END AS tipo_ingreso,
           ROW_NUMBER() OVER (
             PARTITION BY SUBSTR(a.subject_id, 3), a.periodo, CAST(a.tip_doc AS VARCHAR)
             ORDER BY a.p_fecinformacion DESC, a.subject_id ASC) AS rn
    FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir a
    INNER JOIN po b
      ON CAST(a.periodo AS VARCHAR) = b.codmes_drv
     AND SUBSTR(a.subject_id, 3) = b.id_value
    WHERE CAST(a.numcarga AS INT) = 1
  ) r
  WHERE rn = 1
),
cs AS (
  SELECT CAST(codmes AS VARCHAR)                  AS codmes,
         CAST(key_value AS VARCHAR)               AS id_value,
         CAST(CAST(tipdoc AS INTEGER) AS VARCHAR) AS tip_doc,
         MAX(CAST(flg_cs_riesgos AS INTEGER))     AS flg_cs
  FROM e_perm_aws.t_rsk_cta_sueldo
  GROUP BY 1, 2, 3
),
iso AS (
  SELECT * FROM (VALUES
    ('DEP', 0, 0.0023124610, 0.0000000000),
    ('DEP', 1, 0.0318537190, 0.0000000000),
    ('DEP', 2, 0.0318813160, 0.0046349942),
    ('DEP', 3, 0.0497619570, 0.0046349942),
    ('DEP', 4, 0.0497779180, 0.0070308275),
    ('DEP', 5, 0.0850271250, 0.0070308275),
    ('DEP', 6, 0.0850440140, 0.0073891626),
    ('DEP', 7, 0.0921679740, 0.0073891626),
    ('DEP', 8, 0.0921702460, 0.0086767896),
    ('DEP', 9, 0.1010057210, 0.0086767896),
    ('DEP', 10, 0.1010486630, 0.0088495575),
    ('DEP', 11, 0.1092972280, 0.0088495575),
    ('DEP', 12, 0.1093056530, 0.0128865979),
    ('DEP', 13, 0.1174509920, 0.0128865979),
    ('DEP', 14, 0.1174600590, 0.0156895128),
    ('DEP', 15, 0.1744078730, 0.0156895128),
    ('DEP', 16, 0.1744080370, 0.0222419929),
    ('DEP', 17, 0.2033202170, 0.0222419929),
    ('DEP', 18, 0.2033214450, 0.0277777778),
    ('DEP', 19, 0.2043913800, 0.0277777778),
    ('DEP', 20, 0.2044291930, 0.0280898876),
    ('DEP', 21, 0.2104312640, 0.0280898876),
    ('DEP', 22, 0.2104981180, 0.0303030303),
    ('DEP', 23, 0.2114420680, 0.0303030303),
    ('DEP', 24, 0.2114639090, 0.0351537979),
    ('DEP', 25, 0.2643652600, 0.0351537979),
    ('DEP', 26, 0.2644323510, 0.0435413643),
    ('DEP', 27, 0.2910910770, 0.0435413643),
    ('DEP', 28, 0.2911884560, 0.0467625899),
    ('DEP', 29, 0.4012376390, 0.0467625899),
    ('DEP', 30, 0.4012534060, 0.0535714286),
    ('DEP', 31, 0.4057702990, 0.0535714286),
    ('DEP', 32, 0.4058938120, 0.0760869565),
    ('DEP', 33, 0.4289895670, 0.0760869565),
    ('DEP', 34, 0.4291376630, 0.0833333333),
    ('DEP', 35, 0.4305831430, 0.0833333333),
    ('DEP', 36, 0.4305883930, 0.0854092527),
    ('DEP', 37, 0.4565569180, 0.0854092527),
    ('DEP', 38, 0.4565635930, 0.0909090909),
    ('DEP', 39, 0.4628010200, 0.0909090909),
    ('DEP', 40, 0.4628638630, 0.0946327684),
    ('DEP', 41, 0.5533964030, 0.0946327684),
    ('DEP', 42, 0.5534071890, 0.1056105611),
    ('DEP', 43, 0.6094508720, 0.1056105611),
    ('DEP', 44, 0.6095409280, 0.1284403670),
    ('DEP', 45, 0.6738124800, 0.1284403670),
    ('DEP', 46, 0.6744527690, 0.1344086022),
    ('DEP', 47, 0.7615606360, 0.1344086022),
    ('DEP', 48, 0.7626686760, 0.1666666667),
    ('DEP', 49, 0.7902311020, 0.1666666667),
    ('DEP', 50, 0.7902768980, 0.2000000000),
    ('DEP', 51, 0.8258094040, 0.2000000000),
    ('DEP', 52, 0.8262945020, 0.2777777778),
    ('DEP', 53, 0.8563172690, 0.2777777778),
    ('DEP', 54, 0.8587127660, 0.3428571429),
    ('DEP', 55, 0.9782737570, 0.3428571429),
    ('NO DEP', 0, 0.0025374690, 0.0000000000),
    ('NO DEP', 1, 0.0091742180, 0.0000000000),
    ('NO DEP', 2, 0.0092316090, 0.0025104603),
    ('NO DEP', 3, 0.0329928740, 0.0025104603),
    ('NO DEP', 4, 0.0329941150, 0.0062680810),
    ('NO DEP', 5, 0.0584623560, 0.0062680810),
    ('NO DEP', 6, 0.0584755240, 0.0068762279),
    ('NO DEP', 7, 0.0701883450, 0.0068762279),
    ('NO DEP', 8, 0.0702047480, 0.0151143791),
    ('NO DEP', 9, 0.0973640880, 0.0151143791),
    ('NO DEP', 10, 0.0973764490, 0.0159033079),
    ('NO DEP', 11, 0.1146099050, 0.0159033079),
    ('NO DEP', 12, 0.1146149810, 0.0211726384),
    ('NO DEP', 13, 0.1217300240, 0.0211726384),
    ('NO DEP', 14, 0.1217389930, 0.0232134729),
    ('NO DEP', 15, 0.1464291370, 0.0232134729),
    ('NO DEP', 16, 0.1464326050, 0.0267163715),
    ('NO DEP', 17, 0.1852682740, 0.0267163715),
    ('NO DEP', 18, 0.1852819360, 0.0292207792),
    ('NO DEP', 19, 0.1884895980, 0.0292207792),
    ('NO DEP', 20, 0.1885067660, 0.0338729017),
    ('NO DEP', 21, 0.2328721160, 0.0338729017),
    ('NO DEP', 22, 0.2328726790, 0.0457280385),
    ('NO DEP', 23, 0.2580802360, 0.0457280385),
    ('NO DEP', 24, 0.2580953720, 0.0509352518),
    ('NO DEP', 25, 0.3154837450, 0.0509352518),
    ('NO DEP', 26, 0.3154928910, 0.0510204082),
    ('NO DEP', 27, 0.3170212540, 0.0510204082),
    ('NO DEP', 28, 0.3170400990, 0.0583850932),
    ('NO DEP', 29, 0.3318577980, 0.0583850932),
    ('NO DEP', 30, 0.3318683530, 0.0660194175),
    ('NO DEP', 31, 0.3419084810, 0.0660194175),
    ('NO DEP', 32, 0.3419106080, 0.0687500000),
    ('NO DEP', 33, 0.3449538540, 0.0687500000),
    ('NO DEP', 34, 0.3449539320, 0.0769230769),
    ('NO DEP', 35, 0.3456355350, 0.0769230769),
    ('NO DEP', 36, 0.3457517120, 0.0822368421),
    ('NO DEP', 37, 0.4002678890, 0.0822368421),
    ('NO DEP', 38, 0.4002710100, 0.0833333333),
    ('NO DEP', 39, 0.4025117550, 0.0833333333),
    ('NO DEP', 40, 0.4025641840, 0.0909090909),
    ('NO DEP', 41, 0.4046786810, 0.0909090909),
    ('NO DEP', 42, 0.4046909110, 0.0931263858),
    ('NO DEP', 43, 0.4162498480, 0.0931263858),
    ('NO DEP', 44, 0.4162585870, 0.0941990420),
    ('NO DEP', 45, 0.4686123550, 0.0941990420),
    ('NO DEP', 46, 0.4686640260, 0.0975609756),
    ('NO DEP', 47, 0.4698997400, 0.0975609756),
    ('NO DEP', 48, 0.4699433800, 0.1022336770),
    ('NO DEP', 49, 0.5061400590, 0.1022336770),
    ('NO DEP', 50, 0.5061708140, 0.1111111111),
    ('NO DEP', 51, 0.5069139050, 0.1111111111),
    ('NO DEP', 52, 0.5069387070, 0.1114649682),
    ('NO DEP', 53, 0.5302387110, 0.1114649682),
    ('NO DEP', 54, 0.5302792100, 0.1368563686),
    ('NO DEP', 55, 0.5615341470, 0.1368563686),
    ('NO DEP', 56, 0.5615685380, 0.1422518160),
    ('NO DEP', 57, 0.6501171050, 0.1422518160),
    ('NO DEP', 58, 0.6501316740, 0.1571428571),
    ('NO DEP', 59, 0.6558171910, 0.1571428571),
    ('NO DEP', 60, 0.6560647670, 0.1794871795),
    ('NO DEP', 61, 0.6593037280, 0.1794871795),
    ('NO DEP', 62, 0.6594108850, 0.1860465116),
    ('NO DEP', 63, 0.6624613120, 0.1860465116),
    ('NO DEP', 64, 0.6624645350, 0.1991341991),
    ('NO DEP', 65, 0.6805255920, 0.1991341991),
    ('NO DEP', 66, 0.6805548610, 0.2153846154),
    ('NO DEP', 67, 0.6858086880, 0.2153846154),
    ('NO DEP', 68, 0.6859805830, 0.2272727273),
    ('NO DEP', 69, 0.7303485160, 0.2272727273),
    ('NO DEP', 70, 0.7303896950, 0.2500000000),
    ('NO DEP', 71, 0.7315226020, 0.2500000000),
    ('NO DEP', 72, 0.7315691870, 0.2564991334),
    ('NO DEP', 73, 0.8342405380, 0.2564991334),
    ('NO DEP', 74, 0.8343539620, 0.2631578947),
    ('NO DEP', 75, 0.8540539850, 0.2631578947),
    ('NO DEP', 76, 0.8548268300, 0.3125000000),
    ('NO DEP', 77, 0.8602632540, 0.3125000000),
    ('NO DEP', 78, 0.8607611860, 0.3411764706),
    ('NO DEP', 79, 0.9217561560, 0.3411764706),
    ('NO DEP', 80, 0.9237391130, 0.3448275862),
    ('NO DEP', 81, 0.9910335320, 0.3448275862)
  ) AS t(celda, i, x, y)
),
seg AS (
  SELECT celda, x AS x0, y AS y0,
         LEAD(x) OVER (PARTITION BY celda ORDER BY i) AS x1,
         LEAD(y) OVER (PARTITION BY celda ORDER BY i) AS y1
  FROM iso
),
borde AS (
  SELECT celda, MIN(x) AS xmin, MAX(x) AS xmax,
         MIN_BY(y, x) AS ymin, MAX_BY(y, x) AS ymax
  FROM iso GROUP BY celda
),
base AS (
  SELECT d.codmes, d.codmes_drv, d.tip_doc, d.id_value, d.p, d.puntuacion,
         f1.f_t AS f_t_v1,
         f2.f_t AS f_t_v2,
         COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') AS tipo_ingreso,
         CASE WHEN COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') = 'DEPENDIENTE' THEN 'DEP' ELSE 'NO DEP' END AS tipo_ingreso_dep,
         CASE
           WHEN s.id_value IS NULL THEN 'SIN_DATO'
           WHEN COALESCE(s.flg_cs, 0) = 1 THEN 'CS'
           ELSE 'NO_CS'
         END AS flg_cs_estado,
         CAST(CASE WHEN c.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER) AS falla_sin_tipo_ingreso,
         CAST(CASE WHEN s.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER) AS falla_sin_cta_sueldo
  FROM d
  LEFT JOIN cls c
         ON c.id_value = d.id_value AND c.tip_doc = d.tip_doc AND c.codmes = d.codmes_drv
  LEFT JOIN cs s
         ON s.id_value = d.id_value AND s.tip_doc = d.tip_doc
        AND s.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(d.codmes_drv, '%Y%m')), '%Y%m')
  LEFT JOIN ft1 f1 ON f1.codmes_drv = d.codmes_drv
  LEFT JOIN ft2 f2 ON f2.codmes_drv = d.codmes_drv
),
cal AS (
  SELECT b.*,
         CASE WHEN b.tipo_ingreso_dep = 'DEP'
              THEN 1.0/(1.0+exp(-(-1.4235902272 + 1.4307409241*ln(b.p) - 0.1167324222*ln(1.0-b.p))))
              ELSE 1.0/(1.0+exp(-(-1.8712301291 + 1.1219491911*ln(b.p) - 0.5587876582*ln(1.0-b.p))))
         END AS pcal_v1,
         CASE
           WHEN b.p <= bo.xmin THEN bo.ymin
           WHEN b.p >= bo.xmax THEN bo.ymax
           ELSE sg.y0 + (b.p - sg.x0) * (sg.y1 - sg.y0) / (sg.x1 - sg.x0)
         END AS pcal_v2
  FROM base b
  LEFT JOIN borde bo ON bo.celda = b.tipo_ingreso_dep
  LEFT JOIN seg sg   ON sg.celda = b.tipo_ingreso_dep
                    AND b.p >= sg.x0 AND b.p < sg.x1
),
pit AS (
  SELECT cal.*,
         GREATEST(1e-4, LEAST(0.9999, normal_cdf(0.0, 1.0,
           (inverse_normal_cdf(0.0, 1.0, GREATEST(1e-9, LEAST(1.0-1e-9, pcal_v1)))
            + CASE WHEN tipo_ingreso_dep = 'DEP' THEN 0.0517777849 ELSE 0.0511320788 END
            - sqrt(0.0380301160) * 1.0 * f_t_v1) / sqrt(1.0 - 0.0380301160)))) AS pit_v1,
         GREATEST(1e-6, LEAST(0.9999, normal_cdf(0.0, 1.0,
           (inverse_normal_cdf(0.0, 1.0, GREATEST(1e-6, LEAST(1.0-1e-6, pcal_v2)))
            + CASE WHEN tipo_ingreso_dep = 'DEP' THEN 0.0286785656 ELSE -0.0638281623 END
            + 1.0 * f_t_v2) / sqrt(1.0 - 0.0332000000)))) AS pit_v2
  FROM cal
),
fin AS (
  SELECT pit.*,
         GREATEST(1e-4, LEAST(0.9999, normal_cdf(0.0, 1.0,
           inverse_normal_cdf(0.0, 1.0, pit_v1) + 0.0342617216))) AS final_v1,
         GREATEST(0.0003000000, LEAST(0.9999, normal_cdf(0.0, 1.0,
           inverse_normal_cdf(0.0, 1.0, pit_v2)
           + CASE WHEN tipo_ingreso_dep = 'DEP' THEN 0.0746867408 ELSE 0.0733507928 END))) AS final_v2
  FROM pit
)
SELECT codmes,
       codmes_drv,
       tip_doc,
       id_value                AS key_value,
       p                       AS probabilidad,
       puntuacion,
       tipo_ingreso            AS trf_tipo_ingreso,
       tipo_ingreso_dep        AS trf_tipo_ingreso_dep,
       flg_cs_estado           AS trf_flg_cs_estado,
       falla_sin_tipo_ingreso  AS trf_falla_sin_tipo_ingreso,
       falla_sin_cta_sueldo    AS trf_falla_sin_cta_sueldo,
       f_t_v1                  AS trf_f_t_v1,
       f_t_v2                  AS trf_f_t_v2,
       pcal_v1                 AS prob_modelo_cal_v1,
       pcal_v2                 AS prob_modelo_cal_v2,
       pit_v1                  AS prob_modelo_pit_v1,
       pit_v2                  AS prob_modelo_pit_v2,
       final_v1                AS prob_modelo_final_v1,
       final_v2                AS prob_modelo_final_v2,
       CAST(round((1.0 - final_v1) * 1000) AS INTEGER) AS puntuacion_cal_v1,
       CAST(round((1.0 - final_v2) * 1000) AS INTEGER) AS puntuacion_cal_v2
FROM fin
