-- ============================================================================
-- v46. QA del f_t CONGELADO. Cinco chequeos, cada uno con su MAGNITUD.
--
--   GENERADA por 32_genera_sql_ftfreeze.py en la misma corrida que el CTAS.
--
--   QUE MIRAR, en este orden:
--     1_filas          n de la tabla congelada contra la viva. Deben ser iguales.
--                      Si sale 0, falto macro para 202609 y el CROSS JOIN vacio
--                      la tabla -- es la falla que el CROSS JOIN existe para dar.
--     2_ft_unico       n_dist debe ser 1 en v1 y en v2. magnitud = el valor
--                      congelado. ESE es el f_t que manda, no el del cuadro
--                      local, que llevaba dos meses proyectados.
--     3_ft_es_de_202609  el congelado contra el f_t que la propia tabla dice que
--                      le toca a 202609. diff debe ser 0.
--     4_identidad_202609 PD media, min y max de 202609 en las dos tablas. En ese
--                      mes el f_t es el mismo, asi que la PD debe coincidir en
--                      los 15 decimales. magnitud = max del diff absoluto.
--     5_nulos          PD nula en la tabla congelada. Debe ser 0 en v1 y v2.
--
--   La comparacion de 4 es por AGREGADO del mes, no fila a fila: la cadena es
--   deterministica, asi que si media, min y max coinciden a 1e-15 no hay fila
--   que pueda diferir. Se evita a proposito el join por llave, que escanearia
--   los 46 meses de stock (la tabla no esta particionada).
-- ============================================================================
WITH fz AS (
  SELECT CAST(codmes AS VARCHAR)                AS codmes,
         CAST(trf_f_t_v1 AS DOUBLE)             AS ft_v1,
         CAST(trf_f_t_v2 AS DOUBLE)             AS ft_v2,
         CAST(trf_f_t_v1_mes AS DOUBLE)         AS ft_v1_mes,
         CAST(trf_f_t_v2_mes AS DOUBLE)         AS ft_v2_mes,
         CAST(prob_modelo_cal_v1 AS DOUBLE)     AS pd_v1,
         CAST(prob_modelo_cal_v2 AS DOUBLE)     AS pd_v2
  FROM disc_model_owner.scr_stk_ree_pp_cal_v1v2_ftfz2609
),
vv AS (
  SELECT CAST(codmes AS VARCHAR)                AS codmes,
         CAST(prob_modelo_cal_v2 AS DOUBLE)     AS pd_v2
  FROM disc_model_owner.scr_stk_ree_pp_cal_v1v2
),
a1 AS (
  SELECT COUNT(*) AS n_fz,
         COUNT(DISTINCT ft_v1) AS nd1,
         COUNT(DISTINCT ft_v2) AS nd2,
         MAX(ft_v1) AS v1,
         MAX(ft_v2) AS v2,
         MAX(CASE WHEN codmes = '202609' THEN ft_v1_mes END) AS v1m,
         MAX(CASE WHEN codmes = '202609' THEN ft_v2_mes END) AS v2m,
         SUM(CASE WHEN pd_v1 IS NULL THEN 1 ELSE 0 END) AS nul1,
         SUM(CASE WHEN pd_v2 IS NULL THEN 1 ELSE 0 END) AS nul2,
         COUNT(DISTINCT codmes) AS n_meses
  FROM fz
),
a2 AS (
  SELECT COUNT(*) AS n_vv FROM vv
),
s9 AS (
  SELECT AVG(pd_v2) AS m_fz, MIN(pd_v2) AS lo_fz, MAX(pd_v2) AS hi_fz
  FROM fz WHERE codmes = '202609'
),
v9 AS (
  SELECT AVG(pd_v2) AS m_vv, MIN(pd_v2) AS lo_vv, MAX(pd_v2) AS hi_vv
  FROM vv WHERE codmes = '202609'
)
SELECT '1_filas'                                      AS chk,
       CAST(a1.n_fz AS VARCHAR)                       AS n,
       CAST(a2.n_vv AS VARCHAR)                       AS referencia,
       CAST(a1.n_meses AS VARCHAR)                    AS magnitud,
       CASE WHEN a1.n_fz = a2.n_vv AND a1.n_fz > 0 THEN 'OK' ELSE 'REVISAR' END AS veredicto
FROM a1 CROSS JOIN a2
UNION ALL
SELECT '2_ft_unico_v2',
       CAST(a1.nd2 AS VARCHAR),
       '1',
       CAST(ROUND(a1.v2, 10) AS VARCHAR),
       CASE WHEN a1.nd2 = 1 THEN 'OK' ELSE 'REVISAR' END
FROM a1
UNION ALL
SELECT '2_ft_unico_v1',
       CAST(a1.nd1 AS VARCHAR),
       '1',
       CAST(ROUND(a1.v1, 10) AS VARCHAR),
       CASE WHEN a1.nd1 = 1 THEN 'OK' ELSE 'REVISAR' END
FROM a1
UNION ALL
SELECT '3_ft_es_de_202609_v2',
       CAST(ROUND(a1.v2, 10) AS VARCHAR),
       CAST(ROUND(a1.v2m, 10) AS VARCHAR),
       CAST(ROUND(ABS(a1.v2 - a1.v2m), 12) AS VARCHAR),
       CASE WHEN ABS(a1.v2 - a1.v2m) < 1e-12 THEN 'OK' ELSE 'REVISAR' END
FROM a1
UNION ALL
SELECT '3_ft_es_de_202609_v1',
       CAST(ROUND(a1.v1, 10) AS VARCHAR),
       CAST(ROUND(a1.v1m, 10) AS VARCHAR),
       CAST(ROUND(ABS(a1.v1 - a1.v1m), 12) AS VARCHAR),
       CASE WHEN ABS(a1.v1 - a1.v1m) < 1e-12 THEN 'OK' ELSE 'REVISAR' END
FROM a1
UNION ALL
SELECT '4_identidad_202609',
       CAST(ROUND(100.0 * s9.m_fz, 10) AS VARCHAR),
       CAST(ROUND(100.0 * v9.m_vv, 10) AS VARCHAR),
       CAST(ROUND(GREATEST(ABS(s9.m_fz - v9.m_vv),
                           ABS(s9.lo_fz - v9.lo_vv),
                           ABS(s9.hi_fz - v9.hi_vv)), 15) AS VARCHAR),
       CASE WHEN GREATEST(ABS(s9.m_fz - v9.m_vv),
                          ABS(s9.lo_fz - v9.lo_vv),
                          ABS(s9.hi_fz - v9.hi_vv)) < 1e-12 THEN 'OK' ELSE 'REVISAR' END
FROM s9 CROSS JOIN v9
UNION ALL
SELECT '5_nulos',
       CAST(a1.nul2 AS VARCHAR),
       CAST(a1.nul1 AS VARCHAR),
       '0',
       CASE WHEN a1.nul1 = 0 AND a1.nul2 = 0 THEN 'OK' ELSE 'REVISAR' END
FROM a1
ORDER BY 1
