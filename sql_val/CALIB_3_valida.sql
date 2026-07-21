-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : M_mapeo/CALIB_3_valida.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\CALIB_3_valida.sql
--   sha256  : 7f614af5047c   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : valida etapa 1; el bloque 4 contrasta mi target_12m vs el congelado
-- =====================================================================================
-- =====================================================================================
-- CALIB_3_valida.sql | ¿la etapa 1 quedo bien? Correr DESPUES de CALIB_1 y CALIB_2
--
-- EL BLOQUE 4 ES LA PRUEBA DE FUEGO
--   Mi target_12m reconstruido desde RCC madre vs el target_12m de la tabla congelada.
--   Sobre las mismas altas TOP4, con la misma definicion de default, DEBE dar
--   0 discrepancias. Si no da 0, mi port esta mal y no se sigue.
--   Ese numero es lo que autoriza a usar las tempranas: si el 12m reproduce exacto,
--   las de 1m..6m salen de la misma maquinaria y heredan la confianza.
--
-- BLOQUE 2 — algo que el original ASUMIO y aqui se comprueba
--   q1_altas_src dice "rank=1 ya viene aplicado upstream, flg_rank1 es constante=1".
--   Nunca lo verifico contra el dato. Si aparece rank>1, hay altas duplicadas por
--   cohorte y todas las RD estan calculadas sobre un denominador inflado.
--
-- BLOQUE 3 — monotonia
--   El default es acumulado: target_Nm no puede bajar cuando N sube. Una violacion
--   significa que la ventana age<=N esta mal armada. Debe ser 0.
--
-- BLOQUE 5 — la curva de maduracion, que es PARA LO QUE SIRVEN LAS TEMPRANAS
--   RD por horizonte 1m..12m. Dice a que altura se estabiliza el default y por tanto
--   con cuanto horizonte alcanza para medir una cohorte reciente.
--
-- BLOQUE 6 — cuanto se GANA en cobertura
--   Cohortes medibles a 12m (hasta 202505) vs medibles a 6m (hasta 202511).
--
-- READ-ONLY.
-- =====================================================================================

WITH t AS (
  SELECT a.codmes, a.tip_doc, a.key_value, a.personeria, a.flg_ibk, a.rank,
         g.n_obs_ibk_12,
         g.target_1m, g.target_2m, g.target_3m,  g.target_4m,  g.target_5m,  g.target_6m,
         g.target_7m, g.target_8m, g.target_9m, g.target_10m, g.target_11m, g.target_12m
  FROM disc_model_owner.b46029_calib_altas a
  JOIN disc_model_owner.b46029_calib_target g
    ON g.codmes = a.codmes AND g.tip_doc = a.tip_doc AND g.key_value = a.key_value
  WHERE a.top4_entidad = 'TOP4'
)

-- ------------------------------------------------------------------ 1. grano
SELECT '1. GRANO' AS bloque, 'altas TOP4 con target' AS detalle,
       cast(count(*) AS varchar) AS valor, '' AS criterio
FROM t
UNION ALL SELECT '1. GRANO', 'duplicados por (codmes,tip_doc,key_value)',
       cast(count(*) - count(DISTINCT codmes || '|' || tip_doc || '|' || key_value) AS varchar),
       'DEBE ser 0'
FROM t
UNION ALL SELECT '1. GRANO', 'de esas, IBK (flg_ibk=1)',
       cast(count_if(flg_ibk = 1) AS varchar),
       cast(round(100.0 * count_if(flg_ibk = 1) / nullif(count(*),0), 2) AS varchar) || ' %'
FROM t

-- ------------------------------------------------------------------ 2. el supuesto rank=1
UNION ALL SELECT '2. RANK', 'filas con rank <> 1',
       cast(count_if(rank <> 1) AS varchar),
       'el original lo ASUMIO constante=1 y nunca lo verifico'
FROM t
UNION ALL SELECT '2. RANK', 'valores distintos de rank',
       cast(count(DISTINCT rank) AS varchar),
       'si es 1, el supuesto se sostiene'
FROM t

-- ------------------------------------------------------------------ 3. monotonia
UNION ALL SELECT '3. MONOTONIA', 'filas donde target_Nm baja al subir N',
       cast(count_if(target_1m > target_2m OR target_2m > target_3m
                  OR target_3m > target_4m OR target_4m > target_5m
                  OR target_5m > target_6m OR target_6m > target_7m
                  OR target_7m > target_8m OR target_8m > target_9m
                  OR target_9m > target_10m OR target_10m > target_11m
                  OR target_11m > target_12m) AS varchar),
       'DEBE ser 0 — el default es acumulado'
FROM t

-- ------------------------------------------------------------------ 4. LA PRUEBA DE FUEGO
UNION ALL SELECT '4. VS CONGELADA ***', 'altas que cruzan con calib_src',
       cast(count(*) AS varchar), ''
FROM t JOIN disc_model_owner.bnbpe_ibk_calib_src c
  ON c.codmes = t.codmes AND c.tip_doc = t.tip_doc AND c.key_value = t.key_value
 AND c.top4_entidad = 'TOP4'
UNION ALL SELECT '4. VS CONGELADA ***', 'target_12m DISTINTO',
       cast(count_if(t.target_12m <> c.target_12m) AS varchar),
       'DEBE ser 0 — si no, el port esta mal y NO se sigue'
FROM t JOIN disc_model_owner.bnbpe_ibk_calib_src c
  ON c.codmes = t.codmes AND c.tip_doc = t.tip_doc AND c.key_value = t.key_value
 AND c.top4_entidad = 'TOP4'
UNION ALL SELECT '4. VS CONGELADA ***', 'n_obs_ibk_12 DISTINTO',
       cast(count_if(t.n_obs_ibk_12 <> c.n_obs_ibk_12) AS varchar),
       'DEBE ser 0'
FROM t JOIN disc_model_owner.bnbpe_ibk_calib_src c
  ON c.codmes = t.codmes AND c.tip_doc = t.tip_doc AND c.key_value = t.key_value
 AND c.top4_entidad = 'TOP4'
UNION ALL SELECT '4. VS CONGELADA ***', 'altas mias que NO estan en calib_src',
       cast(count(*) AS varchar),
       'esperado > 0 solo si calib_src filtra algo mas'
FROM t LEFT JOIN disc_model_owner.bnbpe_ibk_calib_src c
  ON c.codmes = t.codmes AND c.tip_doc = t.tip_doc AND c.key_value = t.key_value
WHERE c.key_value IS NULL

-- ------------------------------------------------------------------ 5. curva de maduracion
UNION ALL SELECT '5. MADURACION', 'horizonte ' || lpad(cast(h AS varchar), 2, '0') || 'm',
       cast(sum(tgt) AS varchar) || ' / ' || cast(count(*) AS varchar),
       'RD ' || cast(round(100.0 * avg(cast(tgt AS double)), 3) AS varchar) || ' %'
FROM t
CROSS JOIN UNNEST(
  ARRAY[target_1m, target_2m, target_3m,  target_4m,  target_5m,  target_6m,
        target_7m, target_8m, target_9m, target_10m, target_11m, target_12m],
  ARRAY[1,2,3,4,5,6,7,8,9,10,11,12]
) AS x(tgt, h)
WHERE t.flg_ibk = 1 AND cast(t.codmes AS int) BETWEEN 202207 AND 202505
GROUP BY h

-- ------------------------------------------------------------------ 6. lo que ganan las tempranas
UNION ALL SELECT '6. COBERTURA', 'cohortes medibles a 12m (<=202505)',
       cast(count(DISTINCT codmes) AS varchar), 'la ventana actual'
FROM t WHERE cast(codmes AS int) BETWEEN 202207 AND 202505
UNION ALL SELECT '6. COBERTURA', 'cohortes medibles a 6m (<=202511)',
       cast(count(DISTINCT codmes) AS varchar), 'cuanto se estira usando target_6m'
FROM t WHERE cast(codmes AS int) BETWEEN 202207 AND 202511
UNION ALL SELECT '6. COBERTURA', 'altas que suman esos 6 meses extra',
       cast(count(*) AS varchar), 'ganancia de muestra'
FROM t WHERE cast(codmes AS int) BETWEEN 202506 AND 202511

ORDER BY 1, 2
