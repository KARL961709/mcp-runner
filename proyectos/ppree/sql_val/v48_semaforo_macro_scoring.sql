-- ============================================================================
-- v48. SEMAFORO PREVIO AL SCOREO. Correr ANTES del CTAS, no despues.
--
--   POR QUE EXISTE. La cadena V2 usa MA3 de la inflacion interanual con LAG 0: para
--   puntuar el mes M necesita porc_ipc del mes M. El IPC de un mes lo publica el INEI
--   el dia 1 del mes siguiente y el BCRP lo carga despues. Si al momento de correr el
--   CTAS la serie no alcanza el mes objetivo, el HAVING COUNT(yy) = 3 no se cumple,
--   el f_t sale NULL y prob_modelo_cal_v2 sale NULL PARA TODO EL MES, sin error y sin
--   bandera. El CTAS termina OK y la tabla se crea vacia de PD.
--
--   Verificado el 2026-11-04 en la fuente primaria: la serie publica del BCRP
--   (PN01271PM) llegaba a Sep.2026. Octubre no estaba.
--
--   COMO SE LEE, en este orden:
--     ult_mes_ipc        ultimo mes con porc_ipc no nulo en t_mst_bcrp_rsk
--     meses_12m          deben ser 12 para que la interanual del mes objetivo exista
--     meses_ma3          deben ser 3 para que el MA3 exista
--     semaforo           VERDE  -> se puede scorear el mes objetivo con f_t vivo
--                        ROJO   -> NO correr el CTAS contra la tabla viva: la PD
--                                  saldria NULL. Usar la tabla con f_t congelado
--                                  (scr_stk_ree_pp_cal_v1v2_ftfz2609), que no
--                                  depende del mes objetivo porque lee la macro
--                                  en el ancla 202609.
--
--   El mes objetivo esta escrito como literal abajo (hoy 202611). Cambiarlo al mes
--   que se va a scorear antes de correr.
--
--   2026-11-04: el cap del f_t pasa a SOLO PISO, igual que en el CTAS. El techo
--   0.3472136826 que tenia este archivo quedo obsoleto cuando se midio que nunca
--   mordio y que saturaba el overlay.
-- ============================================================================
WITH obj AS (
  SELECT '202611' AS mes_objetivo
),
m AS (
  SELECT CAST(cod_mes AS VARCHAR) AS cod_mes, porc_ipc
  FROM e_perm_aws.t_mst_bcrp_rsk
  WHERE porc_ipc IS NOT NULL
),
cob AS (
  SELECT MAX(cod_mes) AS ult_mes_ipc, COUNT(*) AS n_meses_serie
  FROM m
),
yy AS (
  SELECT o.mes_objetivo, t.k, COUNT(m.porc_ipc) AS n12
  FROM obj o
  CROSS JOIN UNNEST(ARRAY[0, 1, 2]) AS t(k)
  LEFT JOIN m
    ON m.cod_mes BETWEEN DATE_FORMAT(DATE_ADD('month', -(t.k + 11), DATE_PARSE(o.mes_objetivo, '%Y%m')), '%Y%m')
                     AND DATE_FORMAT(DATE_ADD('month', -t.k,        DATE_PARSE(o.mes_objetivo, '%Y%m')), '%Y%m')
  GROUP BY o.mes_objetivo, t.k
),
res AS (
  SELECT mes_objetivo,
         SUM(CASE WHEN n12 = 12 THEN 1 ELSE 0 END) AS meses_ma3,
         MIN(n12) AS min_meses_12m,
         MAX(n12) AS max_meses_12m
  FROM yy
  GROUP BY mes_objetivo
)
SELECT r.mes_objetivo,
       c.ult_mes_ipc,
       c.n_meses_serie,
       r.min_meses_12m                                       AS meses_12m_min,
       r.meses_ma3,
       CASE WHEN r.meses_ma3 = 3 THEN 'VERDE  f_t vivo disponible'
            ELSE 'ROJO   la PD saldria NULL -- usar la tabla con f_t congelado'
       END                                                   AS semaforo,
       CASE WHEN r.meses_ma3 = 3 THEN
              ROUND(GREATEST(-0.0303843813,
                0.0538554432 * ((SELECT AVG(yv) FROM (
                   SELECT (exp(SUM(ln(1.0 + m2.porc_ipc / 100.0))) - 1.0) * 100.0 AS yv
                   FROM UNNEST(ARRAY[0, 1, 2]) AS u(kk)
                   JOIN m m2
                     ON m2.cod_mes BETWEEN DATE_FORMAT(DATE_ADD('month', -(u.kk + 11), DATE_PARSE(r.mes_objetivo, '%Y%m')), '%Y%m')
                                       AND DATE_FORMAT(DATE_ADD('month', -u.kk,        DATE_PARSE(r.mes_objetivo, '%Y%m')), '%Y%m')
                   GROUP BY u.kk) z) - 2.1022638452)), 10)
            ELSE NULL
       END                                                   AS f_t_v2_del_mes_objetivo
FROM res r CROSS JOIN cob c
