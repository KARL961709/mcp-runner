-- ============================================================================
-- V12. FRONTERA TEMPORAL DE LA CADENA V2. READ-ONLY, un statement, agregado.
--
--   V3 y V4 ya median esto, pero con la frontera de V1:
--       mes tope = MIN( pd_max , segmento_max + 1 , macro_max + 6 )
--   El "+6" es la ventana lag5..lag10 de la MA6 de V1. V2 usa MA3 lag 0, que
--   necesita el porc_ipc DEL MES, asi que el termino macro deja de dar aire y
--   pasa a ser restrictivo. Y V3 solo mira la v5: no ve ninguna de las dos
--   hermanas v4, que son las que realmente alimentan calibracion y scoring.
--
--   LOS DOS MESES DE CADA FILA. En Reenganche el archivo rotulado M trae la foto
--   del cierre de M-1, de modo que hay un rotulo y un mes de DERIVACION, y el
--   repo tiene las dos convenciones (02_score usa drv = codmes-1, el 21
--   desplegado usa drv = codmes). V11 lo esta midiendo. Aqui no se elige: se
--   calcula la frontera BAJO LAS DOS y se deja ver cual insumo manda en cada una.
--     A  drv = codmes       tope = MIN( pd_max , seg_max , macro_max )
--     B  drv = codmes - 1   tope = MIN( pd_max , seg_max + 1 , macro_max + 1 )
--   El f_t y el segmento se leen SIEMPRE en drv: el 21 cruza
--   ds_rtd_rskvol_cas_ingr_ir por periodo = codmes_drv, sin rezago.
--
--   OJO CON LA MACRO. t_mst_bcrp_rsk carga tambien la SENDA del vintage vigente,
--   asi que su codmes_max NO es el ultimo mes observado: es el ultimo mes de la
--   senda. Para la columna viva eso significa que el f_t sale, no que el dato
--   exista. El ultimo observado se declara aparte, no se deduce de esta tabla.
--
--   BLOQUES
--     T1  hasta que mes llega cada insumo, con el n del mes tope
--     T2  la frontera bajo las dos convenciones, y quien la amarra
--     T3  densidad de los ultimos meses de los insumos que deciden, para ver si el
--         mes tope es un mes completo o una carga a medias
--
--   El conteo de llaves va con approx_distinct: por mes y sobre tablas de millones de
--   filas un COUNT(DISTINCT) exacto no aporta nada que decida y si puede costar el
--   timeout del runner. El grano EXACTO del _202611_v2 ya lo midio V9 (147,740 filas =
--   147,740 llaves).
-- ============================================================================
WITH pr AS (
  SELECT CAST(codmes AS VARCHAR) AS cm, COUNT(*) AS n,
         approx_distinct(CAST(key_value AS VARCHAR)) AS nk
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
  WHERE pd_comppp_reen_itc IS NOT NULL
  GROUP BY CAST(codmes AS VARCHAR)
),
ps AS (
  SELECT CAST(codmes AS VARCHAR) AS cm, COUNT(*) AS n,
         approx_distinct(CAST(key_value AS VARCHAR)) AS nk
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4
  WHERE pd_comppp_reen_itc IS NOT NULL
  GROUP BY CAST(codmes AS VARCHAR)
),
p5 AS (
  SELECT CAST(codmes AS VARCHAR) AS cm, COUNT(*) AS n,
         approx_distinct(CAST(key_value AS VARCHAR)) AS nk
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov5
  WHERE pd_comppp_reen_itc IS NOT NULL
  GROUP BY CAST(codmes AS VARCHAR)
),
c23 AS (
  SELECT CAST(cod_mes AS VARCHAR) AS cm, COUNT(*) AS n,
         approx_distinct(CAST(key_value AS VARCHAR)) AS nk
  FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610
  WHERE prob_modelo IS NOT NULL
  GROUP BY CAST(cod_mes AS VARCHAR)
),
c11 AS (
  SELECT CAST(cod_mes AS VARCHAR) AS cm, COUNT(*) AS n,
         approx_distinct(CAST(key_value AS VARCHAR)) AS nk
  FROM disc_model_owner.scr_stk_ree_pp_cal_202611_v2
  WHERE prob_modelo IS NOT NULL
  GROUP BY CAST(cod_mes AS VARCHAR)
),
calm AS (
  SELECT CAST(codmes_mrm AS VARCHAR) AS cm, COUNT(*) AS n,
         approx_distinct(CAST(id_value AS VARCHAR)) AS nk
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE pd_raw IS NOT NULL
  GROUP BY CAST(codmes_mrm AS VARCHAR)
),
cals AS (
  SELECT CAST(codmes_scr AS VARCHAR) AS cm, COUNT(*) AS n,
         approx_distinct(CAST(id_value AS VARCHAR)) AS nk
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE pd_raw IS NOT NULL
  GROUP BY CAST(codmes_scr AS VARCHAR)
),
mac AS (
  SELECT CAST(cod_mes AS VARCHAR) AS cm, COUNT(*) AS n, COUNT(*) AS nk
  FROM e_perm_aws.t_mst_bcrp_rsk
  WHERE porc_ipc IS NOT NULL
  GROUP BY CAST(cod_mes AS VARCHAR)
),
seg AS (
  SELECT CAST(periodo AS VARCHAR) AS cm, COUNT(*) AS n,
         approx_distinct(CAST(subject_id AS VARCHAR)) AS nk
  FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
  WHERE CAST(numcarga AS INT) = 1
  GROUP BY CAST(periodo AS VARCHAR)
),
u AS (
  SELECT 'A pd reen v4  (calibracion)' AS insumo, 1 AS ord, cm, n, nk FROM pr
  UNION ALL SELECT 'B pd stock v4 (scoring)', 2, cm, n, nk FROM ps
  UNION ALL SELECT 'C pd v5       (anterior)', 3, cm, n, nk FROM p5
  UNION ALL SELECT 'D scr_cal_2023_202610', 4, cm, n, nk FROM c23
  UNION ALL SELECT 'E scr_cal_202611_v2', 5, cm, n, nk FROM c11
  UNION ALL SELECT 'F ds_stk_ree_pp_cal codmes_mrm', 6, cm, n, nk FROM calm
  UNION ALL SELECT 'G ds_stk_ree_pp_cal codmes_scr', 7, cm, n, nk FROM cals
  UNION ALL SELECT 'H macro porc_ipc (senda incluida)', 8, cm, n, nk FROM mac
  UNION ALL SELECT 'I segmento rtd numcarga 1', 9, cm, n, nk FROM seg
),
mx AS (
  SELECT insumo, ord, MAX(cm) AS cm_max, COUNT(*) AS n_meses FROM u GROUP BY insumo, ord
),
top AS (
  SELECT m.insumo, m.ord, m.cm_max, m.n_meses, x.n, x.nk
  FROM mx m JOIN u x ON x.insumo = m.insumo AND x.cm = m.cm_max
),
f AS (
  SELECT MAX(CASE WHEN ord = 1 THEN cm_max END) AS pd_reen,
         MAX(CASE WHEN ord = 2 THEN cm_max END) AS pd_stk,
         MAX(CASE WHEN ord = 8 THEN cm_max END) AS mac_max,
         MAX(CASE WHEN ord = 9 THEN cm_max END) AS seg_max
  FROM mx
),
fa AS (
  SELECT 'A  drv = codmes' AS conv,
         LEAST(pd_reen, seg_max, mac_max) AS tope,
         pd_reen AS t_pd, seg_max AS t_seg, mac_max AS t_mac
  FROM f
  UNION ALL
  SELECT 'B  drv = codmes - 1',
         LEAST(pd_reen,
               DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(seg_max, '%Y%m')), '%Y%m'),
               DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(mac_max, '%Y%m')), '%Y%m')),
         pd_reen,
         DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(seg_max, '%Y%m')), '%Y%m'),
         DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(mac_max, '%Y%m')), '%Y%m')
  FROM f
)
SELECT CONCAT('T1 ', t.insumo) AS bloque,
       t.cm_max AS mes,
       CAST(t.n AS VARCHAR) AS n,
       CONCAT('llaves aprox en el mes tope ', CAST(t.nk AS VARCHAR), '  meses con dato ',
              CAST(t.n_meses AS VARCHAR)) AS magnitud,
       CASE WHEN t.cm_max >= '202611' THEN 'LLEGA A 202611'
            ELSE CONCAT('NO LLEGA -- se queda en ', t.cm_max) END AS veredicto
FROM top t
UNION ALL
SELECT CONCAT('T2 frontera ', a.conv),
       a.tope,
       '',
       CONCAT('pd ', a.t_pd, '  segmento ', a.t_seg, '  macro ', a.t_mac),
       CASE WHEN a.tope >= '202611' THEN 'alcanza 202611'
            ELSE CONCAT('NO alcanza 202611 -- amarra ',
                   CASE WHEN a.tope = a.t_pd THEN 'la pd'
                        WHEN a.tope = a.t_seg THEN 'el segmento'
                        ELSE 'la macro' END) END
FROM fa a
UNION ALL
SELECT CONCAT('T3 ', x.insumo),
       x.cm,
       CAST(x.n AS VARCHAR),
       CONCAT('llaves aprox ', CAST(x.nk AS VARCHAR)),
       'densidad'
FROM u x
WHERE x.ord IN (1, 2, 9) AND x.cm >= '202609'
ORDER BY 1, 2
