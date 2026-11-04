-- ============================================================================
-- V10. LINAJE de la macro de t_mst_bcrp_rsk. READ-ONLY, un statement, agregado.
--
--   POR QUE. V9 midio que la tabla llega a 202612 y que el MA3 vivo de 202611 sale
--   completo. El INEI publica el IPC de un mes el dia 1 del mes siguiente, asi que al
--   2026-11-04 lo observable es hasta 202610: los meses 202611 y 202612 NO pueden ser
--   dato observado. O la tabla arrastra proyeccion, o arrastra otra serie.
--
--   QUE DECIDE. beta (0.0538554432) y mu (2.1022638452) se estimaron sobre inflacion
--   OBSERVADA, y el expediente declara el driver como CONTEMPORANEO dejando el
--   componente prospectivo expresamente FUERA DE ALCANCE. Si el f_t vivo esta parado
--   sobre proyeccion, prob_modelo_cal es un objeto distinto del que se calibro, y
--   ademas se revisaria: la PD del mismo mes se moveria despues sin que nadie cambie
--   nada. No invalida prob_modelo_cal_freeze, que esta anclada en 202609 (observado y
--   reproducido a 3.9e-11), y que es la columna de campana.
--
--   DOS BLOQUES
--     L1  las columnas de la tabla, en una fila, para ver si hay alguna que distinga
--         observado de proyectado (fuente, flag, escenario, fecha de carga)
--     L2  los ultimos 15 meses con su porc_ipc y la interanual compuesta que implican,
--         para juzgar a ojo donde se corta el dato real
--
--   SI L1 muestra una columna de fuente o de escenario, el paso siguiente es abrir
--   porc_ipc por ese campo. No se puede hacer aqui: referenciar una columna que
--   quizas no existe hace fallar la query entera.
-- ============================================================================
WITH col AS (
  SELECT column_name, data_type, ordinal_position
  FROM information_schema.columns
  WHERE table_schema = 'e_perm_aws' AND table_name = 't_mst_bcrp_rsk'
),
coln AS (
  SELECT COUNT(*) AS n_col,
         array_join(array_agg(CONCAT(column_name, ' ', data_type)
                              ORDER BY ordinal_position), ' | ') AS lista
  FROM col
),
m AS (
  SELECT CAST(cod_mes AS VARCHAR) AS cod_mes, porc_ipc
  FROM e_perm_aws.t_mst_bcrp_rsk
  WHERE porc_ipc IS NOT NULL
),
ult AS (
  SELECT MAX(cod_mes) AS ult FROM m
),
ven AS (
  SELECT m.cod_mes, m.porc_ipc
  FROM m CROSS JOIN ult u
  WHERE m.cod_mes >= DATE_FORMAT(DATE_ADD('month', -14, DATE_PARSE(u.ult, '%Y%m')), '%Y%m')
),
yy AS (
  SELECT v.cod_mes,
         v.porc_ipc,
         (exp(SUM(ln(1.0 + m2.porc_ipc / 100.0))) - 1.0) * 100.0 AS interanual,
         COUNT(m2.porc_ipc) AS n12
  FROM ven v
  JOIN m m2
    ON m2.cod_mes BETWEEN DATE_FORMAT(DATE_ADD('month', -11, DATE_PARSE(v.cod_mes, '%Y%m')), '%Y%m')
                      AND v.cod_mes
  GROUP BY v.cod_mes, v.porc_ipc
)
SELECT 'L1 columnas' AS bloque,
       CAST(c.n_col AS VARCHAR) AS valor,
       c.lista AS detalle,
       'buscar fuente, flag, escenario o fecha de carga' AS lectura
FROM coln c
UNION ALL
SELECT CONCAT('L2 ', y.cod_mes),
       CAST(ROUND(y.porc_ipc, 8) AS VARCHAR),
       CONCAT('interanual ',
              CASE WHEN y.n12 = 12 THEN CAST(ROUND(y.interanual, 8) AS VARCHAR)
                   ELSE CONCAT('incompleta con ', CAST(y.n12 AS VARCHAR), ' meses') END),
       CASE WHEN y.cod_mes <= '202610' THEN 'publicable por el INEI al 2026-11-04'
            ELSE 'NO OBSERVABLE al 2026-11-04 -- tiene que ser proyeccion' END
FROM yy y
ORDER BY 1
