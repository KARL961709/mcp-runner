-- ============================================================================
-- V9. PREFLIGHT del v3 de 202611. READ-ONLY, un statement, todo agregado.
--   Correr ANTES de 30 y 31. Siete bloques, en orden de lo que bloquea:
--
--   P1 la tabla destino ya existe o no        -> decide si hace falta el DROP
--   P2 grano y ventana del _v2                -> el v3 hereda los duplicados que haya
--   P3 prob_modelo: nulos, extremos, escala   -> es el unico insumo que se reutiliza
--   P4 dominio EXACTO de la celda             -> el CASE manda todo lo que no sea DEP
--                                                a NO DEP, y eso no puede ser sorpresa
--   P5 t_mst_bcrp_rsk: grano y cobertura      -> una fila de mas por mes rompe el SUM
--   P6 la macro del ancla medida en el banco  -> el veredicto compara el MA3 contra
--                                                4.3505388516 pct, y reporta el f_t al lado
--   P7 el f_t VIVO del mes puntuado           -> se espera ROJO, hay que confirmarlo
--
--   LO QUE DECIDE DE VERDAD esta en P4: el pct de la celda DEP. El monitoreo ya la
--   tiene en AMBAR (12.59 pct y n = 308 en 202609) con gatillo ROJO en pct < 10 o
--   n < 200. Si en 202611 cruza el gatillo, la segmentacion en dos celdas deja de ser
--   operativa y eso se revisa ANTES de scorear, no despues.
--
--   P6 es el que valida que la macro del banco y la serie local son la misma. Si el
--   MA3 difiere mas de 1e-6, el f_t esperado del expediente no aplica y hay que parar:
--   no es un redondeo, es que las dos fuentes no coinciden.
-- ============================================================================
WITH mac AS (
  SELECT CAST(cod_mes AS VARCHAR) AS cod_mes, porc_ipc
  FROM e_perm_aws.t_mst_bcrp_rsk
  WHERE porc_ipc IS NOT NULL
),
macg AS (
  SELECT cod_mes, COUNT(*) AS n_filas, MIN(LENGTH(cod_mes)) AS len_min,
         MAX(LENGTH(cod_mes)) AS len_max
  FROM mac
  GROUP BY cod_mes
),
macr AS (
  SELECT MAX(cod_mes) AS ult_mes, COUNT(*) AS n_meses,
         MAX(n_filas) AS max_filas_por_mes, MIN(len_min) AS len_min, MAX(len_max) AS len_max,
         SUM(CASE WHEN cod_mes BETWEEN '202508' AND '202609' THEN 1 ELSE 0 END) AS n_ventana_anc
  FROM macg
),
spz AS (
  SELECT '202609' AS cm
),
yyz AS (
  SELECT t.k,
         (exp(SUM(ln(1.0 + m.porc_ipc / 100.0))) - 1.0) * 100.0 AS yy,
         COUNT(m.porc_ipc) AS n12
  FROM spz c
  CROSS JOIN UNNEST(ARRAY[0, 1, 2]) AS t(k)
  JOIN mac m
    ON m.cod_mes BETWEEN DATE_FORMAT(DATE_ADD('month', -(t.k + 11), DATE_PARSE(c.cm, '%Y%m')), '%Y%m')
                     AND DATE_FORMAT(DATE_ADD('month', -t.k,        DATE_PARSE(c.cm, '%Y%m')), '%Y%m')
  GROUP BY t.k
),
ftz AS (
  SELECT SUM(CASE WHEN n12 = 12 THEN 1 ELSE 0 END) AS n_k,
         MIN(n12) AS n12_min,
         MAX(n12) AS n12_max,
         AVG(CASE WHEN n12 = 12 THEN yy END) AS ma3,
         GREATEST(-0.0303843813, 0.0538554432 * (AVG(CASE WHEN n12 = 12 THEN yy END) - 2.1022638452)) AS f_t
  FROM yyz
),
spv AS (
  SELECT '202611' AS cm
),
yyv AS (
  SELECT t.k,
         (exp(SUM(ln(1.0 + m.porc_ipc / 100.0))) - 1.0) * 100.0 AS yy,
         COUNT(m.porc_ipc) AS n12
  FROM spv c
  CROSS JOIN UNNEST(ARRAY[0, 1, 2]) AS t(k)
  JOIN mac m
    ON m.cod_mes BETWEEN DATE_FORMAT(DATE_ADD('month', -(t.k + 11), DATE_PARSE(c.cm, '%Y%m')), '%Y%m')
                     AND DATE_FORMAT(DATE_ADD('month', -t.k,        DATE_PARSE(c.cm, '%Y%m')), '%Y%m')
  GROUP BY t.k
),
ftv AS (
  SELECT SUM(CASE WHEN n12 = 12 THEN 1 ELSE 0 END) AS n_k,
         MIN(n12) AS n12_min,
         MAX(n12) AS n12_max,
         AVG(CASE WHEN n12 = 12 THEN yy END) AS ma3,
         GREATEST(-0.0303843813, 0.0538554432 * (AVG(CASE WHEN n12 = 12 THEN yy END) - 2.1022638452)) AS f_t
  FROM yyv
),
tab AS (
  SELECT COUNT(*) AS n_tgt
  FROM information_schema.tables
  WHERE table_schema = 'disc_model_owner' AND table_name = 'scr_stk_ree_pp_cal_202611_v3'
),
f AS (
  SELECT CAST(cod_mes AS VARCHAR) AS cod_mes,
         CAST(p_codmes AS VARCHAR) AS p_codmes,
         CAST(cod_tip_doc AS VARCHAR) AS tip_doc,
         CAST(key_value AS VARCHAR) AS kv,
         prob_modelo,
         puntuacion,
         woe_trf_tipo_ingreso_dep AS celda_cruda
  FROM disc_model_owner.scr_stk_ree_pp_cal_202611_v2
),
fg AS (
  SELECT COUNT(*) AS n,
         COUNT(DISTINCT CONCAT(cod_mes, '|', tip_doc, '|', kv)) AS n_llaves,
         COUNT(DISTINCT cod_mes) AS n_codmes,
         COUNT(DISTINCT p_codmes) AS n_pcodmes,
         MIN(cod_mes) AS cm_min, MAX(cod_mes) AS cm_max,
         MIN(p_codmes) AS pcm_min, MAX(p_codmes) AS pcm_max,
         SUM(CASE WHEN cod_mes <> p_codmes THEN 1 ELSE 0 END) AS n_cm_ne_pcm,
         COUNT(prob_modelo) AS n_prob,
         MIN(prob_modelo) AS p_min, MAX(prob_modelo) AS p_max, AVG(prob_modelo) AS p_avg,
         SUM(CASE WHEN prob_modelo <= 0.0 THEN 1 ELSE 0 END) AS n_p0,
         SUM(CASE WHEN prob_modelo >= 1.0 THEN 1 ELSE 0 END) AS n_p1,
         SUM(CASE WHEN prob_modelo IS NOT NULL
                   AND CAST(ROUND(1000.0 * (1.0 - prob_modelo)) AS INTEGER) <> puntuacion
                  THEN 1 ELSE 0 END) AS n_punt_ne
  FROM f
),
cel AS (
  SELECT COALESCE(celda_cruda, 'NULO') AS valor,
         COUNT(*) AS n,
         MIN(LENGTH(COALESCE(celda_cruda, ''))) AS len_min,
         MIN(LENGTH(TRIM(COALESCE(celda_cruda, '')))) AS len_trim,
         SUM(CASE WHEN UPPER(TRIM(COALESCE(celda_cruda, ''))) = 'DEP' THEN 1 ELSE 0 END) AS n_a_dep
  FROM f
  GROUP BY COALESCE(celda_cruda, 'NULO')
),
celt AS (
  SELECT SUM(n) AS n_tot, SUM(n_a_dep) AS n_dep FROM cel
)
SELECT 'P1 tabla destino' AS chequeo,
       CAST(t.n_tgt AS VARCHAR) AS n,
       CASE WHEN t.n_tgt = 0 THEN 'scr_stk_ree_pp_cal_202611_v3 no existe -- el DROP es inocuo'
            ELSE 'scr_stk_ree_pp_cal_202611_v3 YA EXISTE -- correr 30 antes de 31' END AS magnitud,
       CASE WHEN t.n_tgt = 0 THEN 'LISTO' ELSE 'DROP PRIMERO' END AS veredicto
FROM tab t
UNION ALL
SELECT 'P2 grano', CAST(g.n AS VARCHAR),
       CONCAT('filas ', CAST(g.n AS VARCHAR), '  llaves ', CAST(g.n_llaves AS VARCHAR),
              '  cod_mes ', CAST(g.n_codmes AS VARCHAR), ' (', g.cm_min, ' a ', g.cm_max,
              ')  p_codmes ', CAST(g.n_pcodmes AS VARCHAR), ' (', g.pcm_min, ' a ',
              g.pcm_max, ')'),
       CASE WHEN g.n = g.n_llaves AND g.n_codmes = 1 AND g.n_pcodmes = 1 THEN 'PASS'
            ELSE 'ATENCION el v3 hereda esto tal cual' END
FROM fg g
UNION ALL
SELECT 'P2b cod_mes vs p_codmes', CAST(g.n_cm_ne_pcm AS VARCHAR),
       CONCAT('filas con cod_mes distinto de p_codmes ', CAST(g.n_cm_ne_pcm AS VARCHAR)),
       CASE WHEN g.n_cm_ne_pcm = 0 THEN 'PASS' ELSE 'ATENCION la particion no es el mes' END
FROM fg g
UNION ALL
SELECT 'P3 prob_modelo', CAST(g.n_prob AS VARCHAR),
       CONCAT('no nulos ', CAST(g.n_prob AS VARCHAR), ' de ', CAST(g.n AS VARCHAR),
              '  min ', CAST(ROUND(g.p_min, 10) AS VARCHAR),
              '  max ', CAST(ROUND(g.p_max, 10) AS VARCHAR),
              '  media ', CAST(ROUND(g.p_avg, 8) AS VARCHAR),
              '  en 0 ', CAST(g.n_p0 AS VARCHAR), '  en 1 ', CAST(g.n_p1 AS VARCHAR)),
       CASE WHEN g.p_min > 0.0 AND g.p_max < 1.0 AND g.p_min >= 0.0 AND g.p_max <= 1.0
            THEN 'PASS' ELSE 'ATENCION el guard 1e-9 va a morder' END
FROM fg g
UNION ALL
SELECT 'P3b convencion puntuacion', CAST(g.n_punt_ne AS VARCHAR),
       CONCAT('filas donde round(1000*(1-prob)) no da puntuacion: ',
              CAST(g.n_punt_ne AS VARCHAR), ' de ', CAST(g.n_prob AS VARCHAR)),
       CASE WHEN g.n_punt_ne = 0 THEN 'PASS round confirmado en toda la tabla'
            ELSE 'REVISAR la convencion no es round' END
FROM fg g
UNION ALL
SELECT CONCAT('P4 celda [', c.valor, ']'), CAST(c.n AS VARCHAR),
       CONCAT('pct ', CAST(ROUND(100.0 * c.n / NULLIF((SELECT n_tot FROM celt), 0), 4) AS VARCHAR),
              '  long ', CAST(c.len_min AS VARCHAR), ' trim ', CAST(c.len_trim AS VARCHAR),
              '  mapea a DEP ', CAST(c.n_a_dep AS VARCHAR)),
       CASE WHEN c.len_min <> c.len_trim THEN 'ATENCION tiene espacios' ELSE 'INFO' END
FROM cel c
UNION ALL
SELECT 'P4b gatillo de celda DEP', CAST(k.n_dep AS VARCHAR),
       CONCAT('n_DEP ', CAST(k.n_dep AS VARCHAR), ' de ', CAST(k.n_tot AS VARCHAR),
              ' = ', CAST(ROUND(100.0 * k.n_dep / NULLIF(k.n_tot, 0), 2) AS VARCHAR), ' pct'),
       CASE WHEN 100.0 * k.n_dep / NULLIF(k.n_tot, 0) < 10.0 OR k.n_dep < 200
            THEN 'ROJO la segmentacion en dos celdas se revisa antes de scorear'
            WHEN 100.0 * k.n_dep / NULLIF(k.n_tot, 0) < 20.0 THEN 'AMBAR igual que en 202609'
            ELSE 'VERDE' END
FROM celt k
UNION ALL
SELECT 'P5 t_mst_bcrp_rsk grano', CAST(r.n_meses AS VARCHAR),
       CONCAT('meses ', CAST(r.n_meses AS VARCHAR), '  ultimo ', r.ult_mes,
              '  max filas por mes ', CAST(r.max_filas_por_mes AS VARCHAR),
              '  long cod_mes ', CAST(r.len_min AS VARCHAR), ' a ',
              CAST(r.len_max AS VARCHAR), '  meses en 202508-202609 ',
              CAST(r.n_ventana_anc AS VARCHAR)),
       CASE WHEN r.max_filas_por_mes = 1 AND r.len_min = 6 AND r.len_max = 6
                 AND r.n_ventana_anc = 14 THEN 'PASS'
            ELSE 'ATENCION una fila de mas por mes rompe el SUM de la interanual' END
FROM macr r
UNION ALL
SELECT 'P6 f_t CONGELADO 202609', COALESCE(CAST(z.n_k AS VARCHAR), '0'),
       CONCAT('ventanas de 12 completas ', CAST(z.n_k AS VARCHAR), ' de 3',
              '  meses por ventana ', COALESCE(CAST(z.n12_min AS VARCHAR), '0'), ' a ',
              COALESCE(CAST(z.n12_max AS VARCHAR), '0'),
              '  MA3 ', COALESCE(CAST(ROUND(z.ma3, 10) AS VARCHAR), 'sin dato'),
              '  esperado 4.3505388516  dif ',
              COALESCE(CAST(ROUND(z.ma3 - 4.3505388516, 12) AS VARCHAR), 'sin dato'),
              '  f_t ', COALESCE(CAST(ROUND(z.f_t, 10) AS VARCHAR), 'sin dato')),
       CASE WHEN COALESCE(z.n_k, 0) < 3 THEN 'ROJO sin macro en el ancla -- el CTAS saldria VACIO'
            WHEN abs(z.ma3 - 4.3505388516) < 1e-6 THEN 'PASS la macro del banco y la local coinciden'
            ELSE 'PARAR el MA3 del banco no es el del expediente' END
FROM ftz z
UNION ALL
SELECT 'P7 f_t VIVO 202611', COALESCE(CAST(v.n_k AS VARCHAR), '0'),
       CONCAT('ventanas de 12 completas ', CAST(v.n_k AS VARCHAR), ' de 3',
              '  meses por ventana ', COALESCE(CAST(v.n12_min AS VARCHAR), '0'), ' a ',
              COALESCE(CAST(v.n12_max AS VARCHAR), '0'),
              CASE WHEN COALESCE(v.n_k, 0) = 3 THEN CONCAT('  MA3 ',
                          COALESCE(CAST(ROUND(v.ma3, 10) AS VARCHAR), 'sin dato'),
                          '  f_t ', COALESCE(CAST(ROUND(v.f_t, 10) AS VARCHAR), 'sin dato'))
                   ELSE '  sin MA3 -- falta el IPC del mes puntuado' END),
       CASE WHEN COALESCE(v.n_k, 0) = 3 THEN 'VERDE prob_modelo_cal sale con numero'
            ELSE 'ROJO ESPERADO prob_modelo_cal sale NULL -- usar la columna freeze' END
FROM ftv v
ORDER BY 1