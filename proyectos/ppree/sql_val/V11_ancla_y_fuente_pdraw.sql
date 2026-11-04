-- ============================================================================
-- V11. LA FUENTE DE pd_raw Y EL ANCLA DEL MES. READ-ONLY, un statement, agregado.
--
--   LA FUENTE existe y esta en disc_riesgos, no en d_perm. Son DOS hermanas:
--     t_b39918_scr_stockpp_itc_reen_reprocesov4   con la que se CALIBRO (50_pd.sql)
--     t_b39918_scr_stockpp_itc_reprocesov4        la que SCOREA el stock (02_score)
--   Columnas: codmes, key_value, cod_tip_doc, pd_comppp_reen_itc, score_comppp_reen_itc.
--   v12 ya midio que comparten convencion de codmes (499,506 pares con PD identica,
--   dif 0.0), pero no se cargan el mismo dia: por eso aqui se miden las dos.
--
--   POR QUE ESTA QUERY BLOQUEA EL CTAS DEL v3. En la familia de Reenganche el archivo
--   rotulado M trae la foto del cierre de M-1, asi que hay dos meses por fila y la
--   cadena los usa para cosas distintas:
--     codmes      el rotulo del archivo
--     codmes_drv  el mes de DERIVACION, donde se leen el f_t y el segmento
--   Y las dos convenciones viven en el repo:
--     02_score_stock_pp.sql:43   codmes_drv = codmes - 1   leyendo el reproceso crudo
--     21_score_v1v2platt.sql     codmes_drv = codmes       leyendo scr_stk_..._2023_202610
--   El _202611_v2 parece seguir la PRIMERA: su trf_macro02 es la MA6 lag5 de porc_ipc
--   evaluada en 202610, no en 202611 (match exacto, medido en 136). Mi 31 evalua el f_t
--   en cod_mes = 202611. Si el _v2 tiene razon, mi f_t esta corrido un mes.
--   Magnitud del corrimiento: f_t 0.132581 en 202610 contra 0.1392710585 en 202611, que
--   son unos +0.06 pp de PD. Chico, pero es correccion, no calibracion.
--
--   COMO SE DECIDE, SIN RAZONAR. Identidad fila a fila de prob_modelo contra la fuente
--   en cada mes candidato. El mes donde n_identica = n_par dice que ESE es el rotulo
--   del archivo que alimento la tabla:
--     si empata en codmes = 202611  ->  cod_mes ES el rotulo  ->  drv = 202610  ->  CORREGIR 31
--     si empata en codmes = 202612  ->  cod_mes YA es el drv  ->  drv = 202611  ->  31 esta bien
--   Se corre el mismo test sobre el ultimo mes de scr_stk_..._2023_202610, que es lo
--   que lee el 21 desplegado, para saber si su cabecera (codmes_drv = codmes) se
--   sostiene o si tambien esta corrida.
--
--   La fuente se agrega por llave ANTES del join: puede traer mas de una fila por
--   (mes, llave, tipo de documento) y un join crudo inflaria los pares.
--
--   BLOQUES
--     C1  cobertura por mes de las dos hermanas, 202601 en adelante
--     C2  identidad de prob_modelo contra cada hermana, por mes candidato
-- ============================================================================
WITH ree AS (
  SELECT CAST(codmes AS VARCHAR) AS cm,
         CAST(cod_tip_doc AS VARCHAR) AS td,
         CAST(key_value AS VARCHAR) AS kv,
         AVG(CAST(pd_comppp_reen_itc AS DOUBLE)) AS p
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
  WHERE pd_comppp_reen_itc IS NOT NULL
    AND CAST(codmes AS VARCHAR) >= '202601'
  GROUP BY CAST(codmes AS VARCHAR), CAST(cod_tip_doc AS VARCHAR), CAST(key_value AS VARCHAR)
),
stk AS (
  SELECT CAST(codmes AS VARCHAR) AS cm,
         CAST(cod_tip_doc AS VARCHAR) AS td,
         CAST(key_value AS VARCHAR) AS kv,
         AVG(CAST(pd_comppp_reen_itc AS DOUBLE)) AS p
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4
  WHERE pd_comppp_reen_itc IS NOT NULL
    AND CAST(codmes AS VARCHAR) >= '202601'
  GROUP BY CAST(codmes AS VARCHAR), CAST(cod_tip_doc AS VARCHAR), CAST(key_value AS VARCHAR)
),
src AS (
  SELECT 'reen  (calibracion)' AS fuente, cm, td, kv, p FROM ree
  UNION ALL
  SELECT 'stock (scoring)' AS fuente, cm, td, kv, p FROM stk
),
cob AS (
  SELECT fuente, cm, COUNT(*) AS n_llaves, AVG(p) AS pd_media
  FROM src
  GROUP BY fuente, cm
),
v2 AS (
  SELECT 'v2_202611' AS tabla,
         CAST(cod_mes AS VARCHAR) AS cm,
         CAST(cod_tip_doc AS VARCHAR) AS td,
         CAST(key_value AS VARCHAR) AS kv,
         AVG(CAST(prob_modelo AS DOUBLE)) AS p
  FROM disc_model_owner.scr_stk_ree_pp_cal_202611_v2
  WHERE prob_modelo IS NOT NULL
  GROUP BY CAST(cod_mes AS VARCHAR), CAST(cod_tip_doc AS VARCHAR), CAST(key_value AS VARCHAR)
),
c23m AS (
  SELECT MAX(CAST(cod_mes AS VARCHAR)) AS ult
  FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610
  WHERE prob_modelo IS NOT NULL
),
c23 AS (
  SELECT 'cal_2023 ult mes' AS tabla,
         CAST(a.cod_mes AS VARCHAR) AS cm,
         CAST(a.cod_tip_doc AS VARCHAR) AS td,
         CAST(a.key_value AS VARCHAR) AS kv,
         AVG(CAST(a.prob_modelo AS DOUBLE)) AS p
  FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610 a
  CROSS JOIN c23m u
  WHERE a.prob_modelo IS NOT NULL
    AND CAST(a.cod_mes AS VARCHAR) = u.ult
  GROUP BY CAST(a.cod_mes AS VARCHAR), CAST(a.cod_tip_doc AS VARCHAR), CAST(a.key_value AS VARCHAR)
),
dst AS (
  SELECT tabla, cm, td, kv, p FROM v2
  UNION ALL
  SELECT tabla, cm, td, kv, p FROM c23
),
cmp AS (
  SELECT d.tabla, d.cm AS cm_dst, s.fuente, s.cm AS cm_src,
         COUNT(*) AS n_par,
         SUM(CASE WHEN abs(s.p - d.p) < 1e-12 THEN 1 ELSE 0 END) AS n_identica,
         MAX(abs(s.p - d.p)) AS dif_max
  FROM dst d
  JOIN src s ON s.td = d.td AND s.kv = d.kv
  GROUP BY d.tabla, d.cm, s.fuente, s.cm
)
SELECT CONCAT('C1 ', c.fuente) AS bloque,
       c.cm AS mes,
       CAST(c.n_llaves AS VARCHAR) AS n,
       CONCAT('pd media ', CAST(ROUND(100.0 * c.pd_media, 4) AS VARCHAR), ' pct') AS magnitud,
       'cobertura' AS lectura
FROM cob c
UNION ALL
SELECT CONCAT('C2 ', k.tabla, ' <- ', k.fuente),
       CONCAT(k.cm_dst, ' vs ', k.cm_src),
       CAST(k.n_par AS VARCHAR),
       CONCAT('identicas ', CAST(k.n_identica AS VARCHAR), ' de ', CAST(k.n_par AS VARCHAR),
              '  dif max ', COALESCE(CAST(ROUND(k.dif_max, 12) AS VARCHAR), 'sin dato')),
       CASE WHEN k.n_identica = k.n_par AND k.n_par > 0
            THEN CONCAT('EMPATA -- el rotulo del archivo es ', k.cm_src)
            WHEN k.n_identica > 0 THEN 'empate PARCIAL -- revisar, puede ser poblacion mixta'
            ELSE 'no empata' END
FROM cmp k
WHERE k.n_par > 0
ORDER BY 1, 2
