-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : D_salida/D1_cobertura.sql
--   origen  : ~\Documents\2026\GDM\Origen_Bank_BN_CALIBRACION_ALINEADA\RUN\D1_cobertura_scoring.sql
--   sha256  : 80c8919fb2d0   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : filas perdidas por JOIN
-- =====================================================================================
-- =====================================================================================
-- CHECK_COBERTURA.sql | correr ANTES de SCORING_FINAL.sql
--
-- Responde tres cosas que deciden si el resultado es confiable:
--   1) cuantas filas sobreviven cada JOIN (y por tanto cuantas NO se puntuan)
--   2) que fraccion trae flg_clean del MAESTRO vs del respaldo RCC
--   3) si algun f_t usado es PROVISIONAL (meses_usados < 3)
--
-- OJO: D1 se escribio cuando el scoring recibia una lista arbitraria a puntuar.
-- En V2 el ladder CONSTRUYE la poblacion desde scr_admbankbpe_rsk, asi que:
--   * la linea 2 (SIN pd_raw) es 0 por construccion — el INNER JOIN de 40 lo garantiza
--   * las lineas 6 y 7 (maestro vs respaldo RCC) ya no aplican: flg_clean sale de 30,
--     no del maestro congelado. Para contrastar contra el maestro esta D4.
-- Lo que SI sigue siendo suyo es la linea 5: f_t PROVISIONAL (meses_usados < 3).
-- READ-ONLY: no crea ni modifica nada.
-- =====================================================================================

WITH entrada AS (
  SELECT cast(codmes AS int) AS codmes,
         cast(tip_doc AS varchar) AS tip_doc,
         key_value
  FROM (SELECT codmes_alta AS codmes, tip_doc, key_value
          FROM disc_model_owner.b46029_po_scoring_v1v2)
  GROUP BY 1,2,3
),

pdr AS (
  SELECT cast(tip_doc AS varchar) AS tip_doc, key_value, cast(p_codmes AS int) AS p_codmes
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE p_codmes BETWEEN (SELECT cast(min(date_format(date_parse(cast(codmes AS varchar),'%Y%m')
                                    - interval '1' month,'%Y%m')) AS varchar) FROM entrada)
                     AND (SELECT cast(max(date_format(date_parse(cast(codmes AS varchar),'%Y%m')
                                    - interval '1' month,'%Y%m')) AS varchar) FROM entrada)
  GROUP BY 1,2,3
),

mst AS (
  SELECT cast(codmes AS int) AS codmes, cast(tip_doc AS varchar) AS tip_doc, key_value,
         max(flg_calib_m2) AS flg_calib_m2
  FROM disc_model_owner.bnbpe_ibk_calib_src
  WHERE cast(codmes AS int) BETWEEN (SELECT min(codmes) FROM entrada)
                                AND (SELECT max(codmes) FROM entrada)
  GROUP BY 1,2,3
),

-- cobertura de la tabla f_t embebida en SCORING_FINAL.sql (202207..202609)
ft AS (
  SELECT codmes_alta, meses_usados FROM (VALUES
    (202207,3),(202208,3),(202209,3),(202210,3),(202211,3),(202212,3),
    (202301,3),(202302,3),(202303,3),(202304,3),(202305,3),(202306,3),
    (202307,3),(202308,3),(202309,3),(202310,3),(202311,3),(202312,3),
    (202401,3),(202402,3),(202403,3),(202404,3),(202405,3),(202406,3),
    (202407,3),(202408,3),(202409,3),(202410,3),(202411,3),(202412,3),
    (202501,3),(202502,3),(202503,3),(202504,3),(202505,3),(202506,3),
    (202507,3),(202508,3),(202509,3),(202510,3),(202511,3),(202512,3),
    (202601,3),(202602,3),(202603,3),(202604,3),(202605,3),(202606,3),
    (202607,3),(202608,3),(202609,2)
  ) AS t(codmes_alta, meses_usados)
),

d AS (
  SELECT e.codmes,
         CASE WHEN p.key_value IS NOT NULL THEN 1 ELSE 0 END AS tiene_pdraw,
         CASE WHEN f.codmes_alta IS NOT NULL THEN 1 ELSE 0 END AS tiene_ft,
         coalesce(f.meses_usados, -1) AS ft_meses,
         CASE WHEN m.flg_calib_m2 IS NOT NULL THEN 'maestro' ELSE 'rcc_parcial' END AS fuente,
         m.flg_calib_m2
  FROM entrada e
  LEFT JOIN pdr p ON p.tip_doc = e.tip_doc AND p.key_value = e.key_value
                 AND p.p_codmes = cast(date_format(date_parse(cast(e.codmes AS varchar),'%Y%m')
                                                   - interval '1' month,'%Y%m') AS int)
  LEFT JOIN ft  f ON f.codmes_alta = e.codmes
  LEFT JOIN mst m ON m.codmes = e.codmes AND m.tip_doc = e.tip_doc AND m.key_value = e.key_value
)

SELECT '1. filas en la tabla de entrada'                   AS chequeo, cast(count(*) AS varchar) AS valor FROM d
UNION ALL SELECT '2. SIN pd_raw  -> NO se puntuan',      cast(count(*) AS varchar) FROM d WHERE tiene_pdraw = 0
UNION ALL SELECT '3. SIN f_t     -> NO se puntuan',      cast(count(*) AS varchar) FROM d WHERE tiene_ft = 0
UNION ALL SELECT '4. PUNTUABLES (con pd_raw y con f_t)',  cast(count(*) AS varchar) FROM d WHERE tiene_pdraw = 1 AND tiene_ft = 1
UNION ALL SELECT '5. ... de esas, f_t PROVISIONAL (<3)',  cast(count(*) AS varchar) FROM d WHERE tiene_pdraw = 1 AND tiene_ft = 1 AND ft_meses BETWEEN 0 AND 2
UNION ALL SELECT '6. ... de esas, flg_clean del MAESTRO', cast(count(*) AS varchar) FROM d WHERE tiene_pdraw = 1 AND tiene_ft = 1 AND fuente = 'maestro'
UNION ALL SELECT '7. ... de esas, flg_clean RESPALDO RCC',cast(count(*) AS varchar) FROM d WHERE tiene_pdraw = 1 AND tiene_ft = 1 AND fuente = 'rcc_parcial'
UNION ALL SELECT '8. %% con maestro (objetivo: 100)',
       cast(round(100.0 * count_if(fuente = 'maestro') / nullif(count(*),0), 2) AS varchar)
       FROM d WHERE tiene_pdraw = 1 AND tiene_ft = 1
UNION ALL SELECT '9. clean/dirty solo donde hay maestro',
       cast(count_if(flg_calib_m2 = 1) AS varchar) || ' clean / ' || cast(count_if(flg_calib_m2 = 0) AS varchar) || ' dirty'
       FROM d WHERE tiene_pdraw = 1 AND tiene_ft = 1 AND fuente = 'maestro'
UNION ALL SELECT '10. rango codmes de la entrada',
       cast(min(codmes) AS varchar) || ' .. ' || cast(max(codmes) AS varchar) FROM d
ORDER BY 1
