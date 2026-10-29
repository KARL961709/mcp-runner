-- ============================================================================
-- 20. PD CALIBRADA del stock PP -- V1 (relanclaje) y V2 FINAL, en paralelo.
--
-- TODO PARTE DE FUENTES MADRE, ninguna tabla intermedia del pipeline:
--   score              disc_model_owner.scr_stk_ree_pp_cal_2023_202610 (prob_modelo)
--   situacion laboral  e_perm_aws.ds_rtd_rskvol_cas_ingr_ir   -> tipo_ingreso
--   cuenta sueldo      e_perm_aws.t_rsk_cta_sueldo            -> flg_cs
--   macro              e_perm_aws.t_mst_bcrp_rsk (porc_ipc)   -> f_t de las dos
--
-- porc_ipc es la variacion MENSUAL del IPC, no la interanual pese al nombre
-- (v29 y el indice ipc: identica al m/m a 1.1e-14 en 86 meses). De ahi:
--   V1  MA6 lag5 de porc_ipc DIRECTO -- la spec del v5, que es mensual
--   V2  interanual COMPUESTA (exp(sum(ln(1+x/100)))-1)*100 sobre 12 meses, luego
--       MA3 lag0 -- la spec de PP VC, que es interanual
--   Son series DISTINTAS, no dos rezagos de la misma. Ese era el error del funnel.
--
-- ANCLA: codmes_drv = codmes. El master 2609 cruza la pd mes con mes (v33 lo
-- probo contra Athena en 6 cohortes de control), asi que los drivers y el f_t se
-- leen en el MISMO mes del score, no en codmes-1 como el SQL anterior.
-- OJO -- SUPUESTO NO VERIFICADO AQUI: que leer los drivers en codmes reproduzca
-- el tipo_ingreso_dep del master. La verificacion de abajo usa el segmento del
-- master, asi que NO lo prueba. Correr antes v39_valida_driver_mes.sql.
--
-- V1 = BetaCal + macro + rho + lambda + cap CONGELADOS del v5. Solo el delta
--      probit se re-resolvio sobre el master 2609 (DEP +0.2211, NO DEP +0.2423).
-- V2 FINAL = isotonica por celda (144 nodos reales del objeto ajustado)
--      + ESCALA a por celda, que corrige el sesgo multiplicativo que introduce
--        dividir por sqrt(1-rho) y que un delta aditivo no puede deshacer
--        (pendiente de calibracion 0.9099 -> 0.9766)
--      + lambda 0.90 -- su optimo medido, y el IC95 [0.25,1.15] lo cubre
--      + SIN cap: el p5/p95 del propio fit era circular y quitarlo cuesta 0.05 pp
--
-- NO LLEVA MoC. El shift del MoC se estimo con lambda=1, a=1 y cap, y no se
-- re-estimo para esta configuracion. Es una capa aparte, no va dentro del CTAS.
--
-- Las dos anclan la LRA del PERIMETRO REENGANCHE, no la del stock. Sobre el stock
-- completo el nivel queda corrido: sirve para comparar V1 contra V2 (mismo sesgo
-- de nivel) y para aterrizar despues a altas por codmes.
--
-- Verificado en 30_genera_sql_final.py contra el pipeline, antes de escribirse:
--   V1 pd_pit 0.0e+00      V2 pd_pit 0.0e+00
-- ============================================================================
CREATE TABLE disc_model_owner.scr_stk_ree_pp_cal_v1v2
WITH (format = 'PARQUET', write_compression = 'SNAPPY') AS
WITH d AS (
  SELECT CAST(v.cod_mes AS VARCHAR) AS codmes,
         CAST(v.cod_mes AS VARCHAR) AS codmes_drv,
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
           (-1.6467199676 - sqrt(1.0 - 0.0380301160) * (-1.9001957962 + 0.6583423568 * AVG(m.porc_ipc)))
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
  CROSS JOIN UNNEST(ARRAY[0, 1, 2]) AS t(k)
  JOIN e_perm_aws.t_mst_bcrp_rsk m
    ON m.cod_mes BETWEEN DATE_FORMAT(DATE_ADD('month', -(t.k + 11), DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
                     AND DATE_FORMAT(DATE_ADD('month', -t.k,        DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
  WHERE m.porc_ipc IS NOT NULL
  GROUP BY c.codmes_drv, t.k
  HAVING COUNT(m.porc_ipc) = 12
),
ft2 AS (
  SELECT codmes_drv,
         GREATEST(-9.9000000000, LEAST(9.9000000000,
           0.0538554432 * (AVG(yy) - 3.7873557149))) AS f_t
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
    ('DEP', 0, 0.0009792800, 0.0000000000),
    ('DEP', 1, 0.0202146130, 0.0000000000),
    ('DEP', 2, 0.0202160510, 0.0039920160),
    ('DEP', 3, 0.0417195960, 0.0039920160),
    ('DEP', 4, 0.0417261000, 0.0082949309),
    ('DEP', 5, 0.0871056120, 0.0082949309),
    ('DEP', 6, 0.0871319130, 0.0095693780),
    ('DEP', 7, 0.0902603890, 0.0095693780),
    ('DEP', 8, 0.0902620800, 0.0142180095),
    ('DEP', 9, 0.0937695710, 0.0142180095),
    ('DEP', 10, 0.0937780760, 0.0181818182),
    ('DEP', 11, 0.0945009560, 0.0181818182),
    ('DEP', 12, 0.0945222150, 0.0249480249),
    ('DEP', 13, 0.1026075470, 0.0249480249),
    ('DEP', 14, 0.1026506790, 0.0264255911),
    ('DEP', 15, 0.1149907160, 0.0264255911),
    ('DEP', 16, 0.1150126630, 0.0289855072),
    ('DEP', 17, 0.1186194710, 0.0289855072),
    ('DEP', 18, 0.1186563750, 0.0291519435),
    ('DEP', 19, 0.1694003410, 0.0291519435),
    ('DEP', 20, 0.1694182180, 0.0297619048),
    ('DEP', 21, 0.1939678820, 0.0297619048),
    ('DEP', 22, 0.1940247050, 0.0331753555),
    ('DEP', 23, 0.2014162300, 0.0331753555),
    ('DEP', 24, 0.2014662390, 0.0344827586),
    ('DEP', 25, 0.2025142250, 0.0344827586),
    ('DEP', 26, 0.2025724620, 0.0355805243),
    ('DEP', 27, 0.2217695260, 0.0355805243),
    ('DEP', 28, 0.2217802740, 0.0370370370),
    ('DEP', 29, 0.2227730090, 0.0370370370),
    ('DEP', 30, 0.2227815280, 0.0393700787),
    ('DEP', 31, 0.2273972300, 0.0393700787),
    ('DEP', 32, 0.2274157660, 0.0434782609),
    ('DEP', 33, 0.2312306750, 0.0434782609),
    ('DEP', 34, 0.2312425520, 0.0448275862),
    ('DEP', 35, 0.2554197250, 0.0448275862),
    ('DEP', 36, 0.2554578970, 0.0495495495),
    ('DEP', 37, 0.2665184760, 0.0495495495),
    ('DEP', 38, 0.2665757040, 0.0518783542),
    ('DEP', 39, 0.2976073770, 0.0518783542),
    ('DEP', 40, 0.2977088210, 0.0714285714),
    ('DEP', 41, 0.3025654810, 0.0714285714),
    ('DEP', 42, 0.3026422300, 0.0741525424),
    ('DEP', 43, 0.4363181910, 0.0741525424),
    ('DEP', 44, 0.4364991620, 0.0776255708),
    ('DEP', 45, 0.4758806350, 0.0776255708),
    ('DEP', 46, 0.4762737710, 0.0882352941),
    ('DEP', 47, 0.4964028880, 0.0882352941),
    ('DEP', 48, 0.4964045490, 0.1363636364),
    ('DEP', 49, 0.5633343020, 0.1363636364),
    ('DEP', 50, 0.5635236040, 0.1464968153),
    ('DEP', 51, 0.6403029630, 0.1464968153),
    ('DEP', 52, 0.6405271460, 0.1643835616),
    ('DEP', 53, 0.7897670430, 0.1643835616),
    ('DEP', 54, 0.7914924540, 0.2000000000),
    ('DEP', 55, 0.8101940460, 0.2000000000),
    ('DEP', 56, 0.8173035580, 0.2962962963),
    ('DEP', 57, 0.9350872770, 0.2962962963),
    ('NO DEP', 0, 0.0017635450, 0.0000000000),
    ('NO DEP', 1, 0.0097506650, 0.0000000000),
    ('NO DEP', 2, 0.0097643730, 0.0059021922),
    ('NO DEP', 3, 0.0239015190, 0.0059021922),
    ('NO DEP', 4, 0.0239031520, 0.0065359477),
    ('NO DEP', 5, 0.0254659220, 0.0065359477),
    ('NO DEP', 6, 0.0254726810, 0.0071428571),
    ('NO DEP', 7, 0.0328430900, 0.0071428571),
    ('NO DEP', 8, 0.0328514590, 0.0089086860),
    ('NO DEP', 9, 0.0365583030, 0.0089086860),
    ('NO DEP', 10, 0.0365734880, 0.0090702948),
    ('NO DEP', 11, 0.0472261410, 0.0090702948),
    ('NO DEP', 12, 0.0472282770, 0.0096153846),
    ('NO DEP', 13, 0.0480231460, 0.0096153846),
    ('NO DEP', 14, 0.0480298080, 0.0098039216),
    ('NO DEP', 15, 0.0502750230, 0.0098039216),
    ('NO DEP', 16, 0.0502765880, 0.0103092784),
    ('NO DEP', 17, 0.0587346990, 0.0103092784),
    ('NO DEP', 18, 0.0587364460, 0.0142555438),
    ('NO DEP', 19, 0.0744869830, 0.0142555438),
    ('NO DEP', 20, 0.0744918730, 0.0180180180),
    ('NO DEP', 21, 0.0756858060, 0.0180180180),
    ('NO DEP', 22, 0.0756872800, 0.0249396621),
    ('NO DEP', 23, 0.0854864490, 0.0249396621),
    ('NO DEP', 24, 0.0854962730, 0.0250671441),
    ('NO DEP', 25, 0.1035197290, 0.0250671441),
    ('NO DEP', 26, 0.1035241780, 0.0313253012),
    ('NO DEP', 27, 0.1106944640, 0.0313253012),
    ('NO DEP', 28, 0.1106944710, 0.0333525014),
    ('NO DEP', 29, 0.1272335540, 0.0333525014),
    ('NO DEP', 30, 0.1272779320, 0.0335174954),
    ('NO DEP', 31, 0.1548961780, 0.0335174954),
    ('NO DEP', 32, 0.1548984240, 0.0396270396),
    ('NO DEP', 33, 0.1595727400, 0.0396270396),
    ('NO DEP', 34, 0.1595807300, 0.0411328388),
    ('NO DEP', 35, 0.1771757370, 0.0411328388),
    ('NO DEP', 36, 0.1771764530, 0.0412844037),
    ('NO DEP', 37, 0.1795505160, 0.0412844037),
    ('NO DEP', 38, 0.1795588230, 0.0521861777),
    ('NO DEP', 39, 0.1882108960, 0.0521861777),
    ('NO DEP', 40, 0.1882230690, 0.0537190083),
    ('NO DEP', 41, 0.1914217970, 0.0537190083),
    ('NO DEP', 42, 0.1914415550, 0.0539232630),
    ('NO DEP', 43, 0.2325426220, 0.0539232630),
    ('NO DEP', 44, 0.2325450910, 0.0645161290),
    ('NO DEP', 45, 0.2330325760, 0.0645161290),
    ('NO DEP', 46, 0.2330373810, 0.0720858896),
    ('NO DEP', 47, 0.2548853470, 0.0720858896),
    ('NO DEP', 48, 0.2548854780, 0.0728269381),
    ('NO DEP', 49, 0.2788013070, 0.0728269381),
    ('NO DEP', 50, 0.2788077220, 0.0778947368),
    ('NO DEP', 51, 0.2886775020, 0.0778947368),
    ('NO DEP', 52, 0.2886873800, 0.0855911330),
    ('NO DEP', 53, 0.3242695480, 0.0855911330),
    ('NO DEP', 54, 0.3242763040, 0.0924308588),
    ('NO DEP', 55, 0.3615328650, 0.0924308588),
    ('NO DEP', 56, 0.3615371120, 0.1164021164),
    ('NO DEP', 57, 0.3784063010, 0.1164021164),
    ('NO DEP', 58, 0.3784656170, 0.1173553719),
    ('NO DEP', 59, 0.3983210530, 0.1173553719),
    ('NO DEP', 60, 0.3983923950, 0.1231281198),
    ('NO DEP', 61, 0.4215956230, 0.1231281198),
    ('NO DEP', 62, 0.4216310000, 0.1343963554),
    ('NO DEP', 63, 0.4595133110, 0.1343963554),
    ('NO DEP', 64, 0.4596226450, 0.1395348837),
    ('NO DEP', 65, 0.4720453830, 0.1395348837),
    ('NO DEP', 66, 0.4720662610, 0.1418312388),
    ('NO DEP', 67, 0.5023566090, 0.1418312388),
    ('NO DEP', 68, 0.5024948790, 0.1436781609),
    ('NO DEP', 69, 0.5126822220, 0.1436781609),
    ('NO DEP', 70, 0.5126905000, 0.1442080378),
    ('NO DEP', 71, 0.5400318660, 0.1442080378),
    ('NO DEP', 72, 0.5400478380, 0.1560000000),
    ('NO DEP', 73, 0.5594091260, 0.1560000000),
    ('NO DEP', 74, 0.5594579750, 0.1579925651),
    ('NO DEP', 75, 0.6154055150, 0.1579925651),
    ('NO DEP', 76, 0.6154801110, 0.1756756757),
    ('NO DEP', 77, 0.6247273740, 0.1756756757),
    ('NO DEP', 78, 0.6248477140, 0.2142857143),
    ('NO DEP', 79, 0.6274751190, 0.2142857143),
    ('NO DEP', 80, 0.6275179070, 0.2264437690),
    ('NO DEP', 81, 0.8057037010, 0.2264437690),
    ('NO DEP', 82, 0.8061548270, 0.2380952381),
    ('NO DEP', 83, 0.8690523170, 0.2380952381),
    ('NO DEP', 84, 0.8696937070, 0.4000000000),
    ('NO DEP', 85, 0.9782056490, 0.4000000000)
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
            + CASE WHEN tipo_ingreso_dep = 'DEP' THEN 0.2210674276 ELSE 0.2423447905 END
            - sqrt(0.0380301160) * 1.0 * f_t_v1) / sqrt(1.0 - 0.0380301160)))) AS pit_v1,
         GREATEST(1e-6, LEAST(0.9999, normal_cdf(0.0, 1.0,
           (CASE WHEN tipo_ingreso_dep = 'DEP' THEN 0.9701736450 ELSE 0.8839044164 END
            * inverse_normal_cdf(0.0, 1.0, GREATEST(1e-6, LEAST(1.0-1e-6, pcal_v2)))
            + CASE WHEN tipo_ingreso_dep = 'DEP' THEN -0.0196348230 ELSE -0.2147385080 END
            + 0.90 * f_t_v2) / sqrt(1.0 - 0.0332000000)))) AS pit_v2
  FROM cal
),
fin AS (
  SELECT pit.* FROM pit
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
       pcal_v1                 AS trf_betacal_v1,
       pcal_v2                 AS trf_isotonica_v2,
       pit_v1                  AS prob_modelo_cal_v1,
       pit_v2                  AS prob_modelo_cal_v2,
       CAST(round((1.0 - pit_v1) * 1000) AS INTEGER) AS puntuacion_cal_v1,
       CAST(round((1.0 - pit_v2) * 1000) AS INTEGER) AS puntuacion_cal_v2
FROM fin
