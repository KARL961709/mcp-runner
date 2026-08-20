-- =====================================================================================
-- ORIGEN BPE PD - V2 - VALIDACION (read-only)
--   archivo : C_calibra/C15_impacto_umbral_saldo.sql
--   estado  : NUEVO
--   nota    : impacto de subir el piso de saldo 30k -> 50/75/100k sobre poblacion y RD
-- =====================================================================================
-- C15_impacto_umbral_saldo.sql | cuanto se mueve si el filtro de monto sube de 30k
--
-- POR QUE SE PLANTEA
--   El filtro de saldo (flg_monto) hoy es:
--     (max_saldo >= 30000 AND saldo_m0 IN [10000, 30000)) OR saldo_m0 >= 30000
--   Pregunta: si el piso sube a 75k (o 50/100k), cuanto libro se pierde y como se
--   mueve la RD. Si el tramo que se cae [30k,75k) incumple MAS que el que queda, subir
--   el piso baja la mora (es composicion por monto, hipotesis abierta de C6). Si incumple
--   menos, se estaria botando buen negocio.
--   Regla por umbral T (piso proporcional T/3, igual que hoy 10k para 30k):
--     (max_saldo >= T AND saldo_m0 IN [T/3, T)) OR saldo_m0 >= T
--
-- OJO (C7): saldo_m0/max_saldo son del SISTEMA (no de IBK): el filtro ya es permisivo.
--   Aca se mide sobre la MISMA base que el filtro vigente para que la comparacion 30 vs 75
--   sea directa. La correccion a IBK es un eje aparte (C7).
--
-- Ventana 202207-202505 (12m cerrados, RD solida), sin impulsa ni reactiva_puro.
-- ~35 filas. READ-ONLY.
-- =====================================================================================

WITH a AS (
  SELECT cast(c.codmes AS int) AS codmes, c.personeria,
         cast(al.saldo_m0  AS double) AS s0,
         cast(al.max_saldo AS double) AS maxs,
         cast(c.target_12m AS double) AS y,
         coalesce(c.flg_calib_m2, 0)  AS clean_hoy
  FROM disc_model_owner.bnbpe_ibk_calib_src c
  JOIN disc_model_owner.bnbpe_ibk_altas_src al
    ON al.codmes = c.codmes AND al.tip_doc = c.tip_doc AND al.key_value = c.key_value
  WHERE c.flg_ibk = 1 AND c.top4_entidad = 'TOP4'
    AND coalesce(c.flg_impulsa, 0) = 0 AND coalesce(c.flg_reactiva_puro, 0) = 0
    AND cast(c.codmes AS int) BETWEEN 202207 AND 202505
    AND c.target_12m IS NOT NULL
),
r AS (
  SELECT *,
    CASE WHEN (maxs >= 30000  AND s0 >= 10000 AND s0 < 30000)  OR s0 >= 30000  THEN 1 ELSE 0 END AS m30,
    CASE WHEN (maxs >= 50000  AND s0 >= 16667 AND s0 < 50000)  OR s0 >= 50000  THEN 1 ELSE 0 END AS m50,
    CASE WHEN (maxs >= 75000  AND s0 >= 25000 AND s0 < 75000)  OR s0 >= 75000  THEN 1 ELSE 0 END AS m75,
    CASE WHEN (maxs >= 100000 AND s0 >= 33333 AND s0 < 100000) OR s0 >= 100000 THEN 1 ELSE 0 END AS m100
  FROM a
)

-- ------------------------------------------------- 1. poblacion que SOBREVIVE cada piso
SELECT '1. UMBRAL 30k (hoy)' AS bloque, personeria,
       cast(count_if(m30 = 1) AS varchar) AS n,
       cast(round(100.0 * count_if(m30 = 1) / nullif(count(*), 0), 1) AS varchar) || ' % pob' AS cobertura,
       'RD ' || cast(round(100.0 * sum(CASE WHEN m30 = 1 THEN y END) / nullif(count_if(m30 = 1), 0), 2) AS varchar) || ' %' AS rd
FROM r GROUP BY personeria
UNION ALL
SELECT '2. UMBRAL 50k', personeria,
       cast(count_if(m50 = 1) AS varchar),
       cast(round(100.0 * count_if(m50 = 1) / nullif(count(*), 0), 1) AS varchar) || ' % pob',
       'RD ' || cast(round(100.0 * sum(CASE WHEN m50 = 1 THEN y END) / nullif(count_if(m50 = 1), 0), 2) AS varchar) || ' %'
FROM r GROUP BY personeria
UNION ALL
SELECT '3. UMBRAL 75k', personeria,
       cast(count_if(m75 = 1) AS varchar),
       cast(round(100.0 * count_if(m75 = 1) / nullif(count(*), 0), 1) AS varchar) || ' % pob',
       'RD ' || cast(round(100.0 * sum(CASE WHEN m75 = 1 THEN y END) / nullif(count_if(m75 = 1), 0), 2) AS varchar) || ' %'
FROM r GROUP BY personeria
UNION ALL
SELECT '4. UMBRAL 100k', personeria,
       cast(count_if(m100 = 1) AS varchar),
       cast(round(100.0 * count_if(m100 = 1) / nullif(count(*), 0), 1) AS varchar) || ' % pob',
       'RD ' || cast(round(100.0 * sum(CASE WHEN m100 = 1 THEN y END) / nullif(count_if(m100 = 1), 0), 2) AS varchar) || ' %'
FROM r GROUP BY personeria

-- ------------------------------------------------- 2. el tramo que se CAE al pasar de 30k a 75k
UNION ALL
SELECT '5. SALE 30->75k', personeria,
       cast(count_if(m30 = 1 AND m75 = 0) AS varchar),
       'def ' || cast(sum(CASE WHEN m30 = 1 AND m75 = 0 THEN y ELSE 0 END) AS varchar),
       'RD ' || cast(round(100.0 * sum(CASE WHEN m30 = 1 AND m75 = 0 THEN y END) / nullif(count_if(m30 = 1 AND m75 = 0), 0), 2) AS varchar) || ' %'
FROM r GROUP BY personeria

-- ------------------------------------------------- 3. composicion por anio: RD chico vs grande
-- Si el libro reciente es mas big-ticket y el chico incumple mas, parte de la sobre-prediccion
-- es composicion por monto (hipotesis C6), no ciclo.
UNION ALL
SELECT '6. COMP ' || cast(cast(codmes / 100 AS int) AS varchar), personeria,
       cast(count(*) AS varchar),
       cast(round(100.0 * count_if(s0 < 30000) / nullif(count(*), 0), 1) AS varchar) || ' % <30k',
       'RD <30k ' || cast(round(100.0 * sum(CASE WHEN s0 < 30000 THEN y END) / nullif(count_if(s0 < 30000), 0), 2) AS varchar)
       || ' % vs >=75k ' || cast(round(100.0 * sum(CASE WHEN s0 >= 75000 THEN y END) / nullif(count_if(s0 >= 75000), 0), 2) AS varchar) || ' %'
FROM r GROUP BY cast(codmes / 100 AS int), personeria

ORDER BY 1, 2
