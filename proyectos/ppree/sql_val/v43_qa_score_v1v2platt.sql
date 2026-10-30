-- ============================================================================
-- v43. QA del CTAS 21_score_v1v2platt. Reproduce el pipeline sobre el fit
--
--   GENERADA por 31_genera_sql_v2platt.py en la MISMA corrida que el CTAS. No se
--   edita a mano: la ventana y las anclas se inyectan desde la config y el
--   pipeline, asi que no pueden quedar desincronizadas del build (R12).
--
--   El generador ya probo que los COEFICIENTES reproducen el pipeline en Python.
--   Lo que esa prueba NO cubre es la aritmetica del SQL: la macro recalculada
--   desde porc_ipc, la cadena Platt (logit, exp, inverse_normal_cdf), los clips,
--   el piso y el join del segmento. Eso se verifica aca contra numeros conocidos.
--
--   OJO -- V1 y V2 NO ANCLAN EN LA MISMA VENTANA, y por eso no se les puede
--   pedir el mismo EC aqui:
--     V1  202301-202509  (n = 49,430, malos = 2462)  incluye HIST_PROXY
--     V2  202401-202509  (n = 30,528, malos = 954)  SOLO perimetro verificado
--   HIST_PROXY es reenganche no verificado con RD 7.98 pct contra 3.13 pct, y la
--   spec cerrada lo excluye a proposito.
--
--   CONTRA QUE SE COMPARA. El ancla del metodo es la MEDIA DE LAS RD MENSUALES
--   -- cada mes pesa igual, sin importar su n -- y NO la RD pooled de la ventana.
--   Las dos difieren y confundirlas manda a buscar un defecto que no existe:
--     DEP     pooled 2.8157 pct   media mensual 2.8157 pct
--     NO DEP  pooled 3.3085 pct   media mensual 3.3085 pct
--   Por eso la salida trae rd_ancla (la media mensual) junto a rd_pooled, y el
--   veredicto es ec_v2_vs_ancla: ESE es el que debe dar ~0. ec_v2_vs_pooled se
--   reporta al lado para que la brecha quede a la vista, no para juzgar.
--
--   ec_v1_vs_pooled NO cierra y no debe cerrar: V1 esta anclado sobre
--   202301-202509, que incluye HIST_PROXY.
--
--   OJO CON ft_v2_max: esta QA solo mira 202401-202509, asi que su maximo es
--   el de 202401. NO dice nada sobre la cobertura de los meses de aplicacion
--   posteriores: eso lo responde v45.
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
    AND codmes_mrm BETWEEN '202401' AND '202509'
),
j AS (
  SELECT g.celda_master, g.codmes, g.y, s.pd_v1, s.pd_v2, s.ft_v1, s.ft_v2,
         CASE WHEN s.celda = g.celda_master THEN 1 ELSE 0 END AS celda_ok,
         CASE WHEN s.id_value IS NULL THEN 1 ELSE 0 END       AS no_cruza
  FROM g
  LEFT JOIN s ON s.codmes = g.codmes AND s.tip_doc = g.tip_doc AND s.id_value = g.id_value
),
mm AS (
  SELECT celda_master, codmes, AVG(y) AS rd_m
  FROM j
  GROUP BY GROUPING SETS ((celda_master, codmes), (codmes))
),
anc AS (
  SELECT COALESCE(celda_master, 'GLOBAL') AS celda, AVG(rd_m) AS rd_ancla, COUNT(*) AS n_meses
  FROM mm GROUP BY celda_master
),
agg AS (
SELECT COALESCE(celda_master, 'GLOBAL')                                  AS celda,
       COUNT(*)                                                          AS n,
       SUM(no_cruza)                                                     AS n_sin_cruce,
       SUM(CASE WHEN no_cruza = 0 THEN celda_ok ELSE 0 END)              AS n_celda_ok,
       ROUND(100.0 * AVG(y), 4)                                          AS rd_pooled,
       ROUND(100.0 * AVG(pd_v1), 4)                                      AS pd_v1,
       ROUND(100.0 * AVG(pd_v2), 4)                                      AS pd_v2,
       ROUND(MIN(ft_v1), 6)                                              AS ft_v1_min,
       ROUND(MAX(ft_v1), 6)                                              AS ft_v1_max,
       ROUND(MIN(ft_v2), 6)                                              AS ft_v2_min,
       ROUND(MAX(ft_v2), 6)                                              AS ft_v2_max
FROM j
GROUP BY GROUPING SETS ((celda_master), ())
)
SELECT a.celda, a.n, a.n_sin_cruce, a.n_celda_ok, c.n_meses,
       ROUND(100.0 * c.rd_ancla, 4)                                      AS rd_ancla,
       a.rd_pooled,
       a.pd_v1, a.pd_v2,
       ROUND(100.0 * (a.pd_v2 / 100.0 / NULLIF(c.rd_ancla, 0) - 1.0), 4) AS ec_v2_vs_ancla,
       ROUND(100.0 * (a.pd_v2 / NULLIF(a.rd_pooled, 0) - 1.0), 4)        AS ec_v2_vs_pooled,
       ROUND(100.0 * (a.pd_v1 / NULLIF(a.rd_pooled, 0) - 1.0), 4)        AS ec_v1_vs_pooled,
       a.ft_v1_min, a.ft_v1_max, a.ft_v2_min, a.ft_v2_max
FROM agg a JOIN anc c ON c.celda = a.celda
ORDER BY 1
