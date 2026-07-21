-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : M_mapeo/M3_embudo_calibracion.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\M3_embudo_calibracion.sql
--   sha256  : 0de4228f31f5   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : de la PO a la poblacion que se calibro
-- =====================================================================================
-- =====================================================================================
-- M3_embudo_calibracion.sql | de la PO a la poblacion que se calibro
--
-- M1 perfila las fuentes · M2 mide cuanto de la PO alcanzan · M3 cierra el recorrido:
-- de todos los que tienen score, quienes terminaron entrando al ajuste de coeficientes.
--
-- Se corre sobre bnbpe_ibk_calib_src, la base CONGELADA. Es la unica que tiene
-- target_12m y flg_calib_m2 juntos, o sea la unica donde el embudo es observable.
--
-- EL RECORRIDO
--   altas totales
--     -> perimetro IBK            flg_ibk = 1
--     -> TOP4                     top4_entidad = 'TOP4'
--     -> maduracion cerrada       codmes <= 202505 (12m para observar el default)
--     -> sin programa             sin impulsa ni reactiva_puro   <- corte de APRENDIZAJE
--     -> clean / dirty            flg_calib_m2                   <- corte de CADENA
--
-- LOS DOS CORTES NO SON EL MISMO Y ES A PROPOSITO
--   impulsa/reactiva salen del APRENDIZAJE de coeficientes (incluirlos sesga), pero NO
--   son criterio de separacion clean/dirty en produccion. Por eso el AND de 30 tiene
--   17 condiciones y no 19. Este embudo muestra los dos cortes por separado para que
--   se vea que uno no arrastra al otro.
--
-- Para el aporte de CADA filtro por separado esta F1_mapa_filtros. Aqui es el recorrido.
--
-- ~20 filas. READ-ONLY.
-- =====================================================================================

WITH b AS (
  SELECT cast(codmes AS int)                         AS codmes,
         cast(tip_doc AS varchar)                    AS tip_doc,
         key_value,
         coalesce(flg_ibk, 0)                        AS flg_ibk,
         top4_entidad,
         coalesce(flg_calib_m2, 0)                   AS flg_calib_m2,
         target_12m,
         coalesce(flg_impulsa, 0)                    AS flg_impulsa,
         coalesce(flg_reactiva_puro, 0)              AS flg_reactiva_puro,
         CASE WHEN cast(tip_doc AS varchar) = '2' THEN 'PJJ' ELSE 'PNN' END AS personeria
  FROM disc_model_owner.bnbpe_ibk_calib_src
),
e AS (
  SELECT *,
         CASE WHEN flg_ibk = 1                                        THEN 1 ELSE 0 END AS p1_ibk,
         CASE WHEN flg_ibk = 1 AND top4_entidad = 'TOP4'              THEN 1 ELSE 0 END AS p2_top4,
         CASE WHEN flg_ibk = 1 AND top4_entidad = 'TOP4'
               AND codmes BETWEEN 202207 AND 202505                   THEN 1 ELSE 0 END AS p3_madura,
         CASE WHEN flg_ibk = 1 AND top4_entidad = 'TOP4'
               AND codmes BETWEEN 202207 AND 202505
               AND flg_impulsa = 0 AND flg_reactiva_puro = 0          THEN 1 ELSE 0 END AS p4_aprende
  FROM b
)

-- ------------------------------------------------------------------ 1. el embudo
SELECT '1. EMBUDO' AS bloque, '0 · altas en la base congelada' AS paso,
       cast(count(*) AS varchar) AS n, '100.00 %' AS pct_del_paso_previo, '' AS nota
FROM e
UNION ALL SELECT '1. EMBUDO', '1 · perimetro IBK  (flg_ibk = 1)',
       cast(sum(p1_ibk) AS varchar),
       cast(round(100.0 * sum(p1_ibk) / nullif(count(*),0), 2) AS varchar) || ' %', ''
FROM e
UNION ALL SELECT '1. EMBUDO', '2 · TOP4  (top4_entidad)',
       cast(sum(p2_top4) AS varchar),
       cast(round(100.0 * sum(p2_top4) / nullif(sum(p1_ibk),0), 2) AS varchar) || ' %', ''
FROM e
UNION ALL SELECT '1. EMBUDO', '3 · maduracion cerrada  (202207..202505)',
       cast(sum(p3_madura) AS varchar),
       cast(round(100.0 * sum(p3_madura) / nullif(sum(p2_top4),0), 2) AS varchar) || ' %',
       '12m para observar el default'
FROM e
UNION ALL SELECT '1. EMBUDO', '4 · sin impulsa ni reactiva  -> APRENDIZAJE',
       cast(sum(p4_aprende) AS varchar),
       cast(round(100.0 * sum(p4_aprende) / nullif(sum(p3_madura),0), 2) AS varchar) || ' %',
       'este es el corte que define sobre QUE se ajustaron los coeficientes'
FROM e

-- ------------------------------------------------------------------ 2. el corte de cadena
UNION ALL SELECT '2. CLEAN / DIRTY',
       'del aprendizaje: ' || CASE WHEN flg_calib_m2 = 1 THEN 'CLEAN' ELSE 'DIRTY' END,
       cast(count(*) AS varchar),
       cast(round(100.0 * count(*) / nullif(sum(count(*)) OVER (), 0), 2) AS varchar) || ' %',
       'RD ' || cast(round(100.0 * avg(cast(target_12m AS double)), 2) AS varchar) || ' %'
FROM e WHERE p4_aprende = 1 GROUP BY flg_calib_m2

UNION ALL SELECT '2. CLEAN / DIRTY',
       'por personeria: ' || personeria
       || ' / ' || CASE WHEN flg_calib_m2 = 1 THEN 'CLEAN' ELSE 'DIRTY' END,
       cast(count(*) AS varchar),
       cast(round(100.0 * count(*) / nullif(sum(count(*)) OVER (), 0), 2) AS varchar) || ' %',
       'RD ' || cast(round(100.0 * avg(cast(target_12m AS double)), 2) AS varchar) || ' %'
       || ' · defaults ' || cast(sum(target_12m) AS varchar)
FROM e WHERE p4_aprende = 1 GROUP BY personeria, flg_calib_m2

-- ------------------------------------------------------------------ 3. lo que se excluyo
-- No desaparecen: en produccion SI se puntuan. Solo no entran al ajuste.
UNION ALL SELECT '3. EXCLUIDOS DEL AJUSTE',
       CASE WHEN flg_impulsa = 1 AND flg_reactiva_puro = 1 THEN 'impulsa Y reactiva'
            WHEN flg_impulsa = 1                           THEN 'impulsa'
            ELSE 'reactiva_puro' END,
       cast(count(*) AS varchar),
       cast(round(100.0 * count(*) / nullif(sum(count(*)) OVER (), 0), 2) AS varchar) || ' %',
       'RD ' || cast(round(100.0 * avg(cast(target_12m AS double)), 2) AS varchar) || ' %'
       || ' · EN PRODUCCION SI SE PUNTUAN'
FROM e
WHERE p3_madura = 1 AND (flg_impulsa = 1 OR flg_reactiva_puro = 1)
GROUP BY CASE WHEN flg_impulsa = 1 AND flg_reactiva_puro = 1 THEN 'impulsa Y reactiva'
              WHEN flg_impulsa = 1                           THEN 'impulsa'
              ELSE 'reactiva_puro' END

-- ------------------------------------------------------------------ 4. por anio
-- El quiebre estructural de 2024 se ve aqui: mismo perimetro, RD a un tercio.
UNION ALL SELECT '4. POR ANIO', cast(cast(codmes / 100 AS int) AS varchar),
       cast(count(*) AS varchar),
       cast(round(100.0 * count_if(flg_calib_m2 = 1) / nullif(count(*),0), 2) AS varchar) || ' % clean',
       'RD ' || cast(round(100.0 * avg(cast(target_12m AS double)), 2) AS varchar) || ' %'
FROM e WHERE p4_aprende = 1 GROUP BY cast(codmes / 100 AS int)

ORDER BY 1, 2
