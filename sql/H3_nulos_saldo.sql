-- =====================================================================================
-- H3 | CORRIGE H2 — ¿los saldos historicos vienen NULL o cero?
--
-- DEFECTO DE H2: no distinguia NULL de 0. En SQL, NULL + x = NULL, y `NULL = 0` no es
-- TRUE, asi que ninguna rama de la cascada se cumple y TODO cae al ELSE 'A-00'.
-- Un cliente realmente nuevo (12 meses sin saldo, guardados como NULL) apareceria
-- como "saldo continuo" — justo lo contrario de lo que es.
--
-- Dos sintomas de H2 que apuntan al mismo bug:
--   * A-12 no aparecio NI UNA VEZ (imposible si la tabla no estuviera filtrada)
--   * 92% de IBK cayo en A-00
--
-- BLOQUE 1  cuantos NULL hay en cada saldo_mN. Si son muchos, H2 esta mal.
-- BLOQUE 2  la MISMA cascada pero con coalesce(saldo, 0). Es la lectura correcta
--           si los NULL representan "sin saldo ese mes".
-- BLOQUE 3  contraste directo: reparto con NULL crudo vs con coalesce, solo IBK.
--
-- READ-ONLY.
-- =====================================================================================

WITH b AS (
  SELECT
    CASE WHEN cod_instit_financiera = '00002' THEN 'IBK' ELSE 'resto' END AS ent,
    cast(saldo_m0 AS double) AS s0,
    coalesce(cast(saldo_m1 AS double), 0)  AS c1,  coalesce(cast(saldo_m2 AS double), 0)  AS c2,
    coalesce(cast(saldo_m3 AS double), 0)  AS c3,  coalesce(cast(saldo_m4 AS double), 0)  AS c4,
    coalesce(cast(saldo_m5 AS double), 0)  AS c5,  coalesce(cast(saldo_m6 AS double), 0)  AS c6,
    coalesce(cast(saldo_m7 AS double), 0)  AS c7,  coalesce(cast(saldo_m8 AS double), 0)  AS c8,
    coalesce(cast(saldo_m9 AS double), 0)  AS c9,  coalesce(cast(saldo_m10 AS double), 0) AS c10,
    coalesce(cast(saldo_m11 AS double), 0) AS c11, coalesce(cast(saldo_m12 AS double), 0) AS c12,
    CASE WHEN saldo_m1 IS NULL THEN 1 ELSE 0 END AS nl1,
    CASE WHEN saldo_m6 IS NULL THEN 1 ELSE 0 END AS nl6,
    CASE WHEN saldo_m12 IS NULL THEN 1 ELSE 0 END AS nl12,
    CASE WHEN saldo_m0 IS NULL THEN 1 ELSE 0 END AS nl0
  FROM disc_monitorian.t_dan_mrm_admbankbpe_altas_rep
  WHERE p_codmes BETWEEN '202601' AND '202604'
    AND cast(codmes AS int) BETWEEN 202601 AND 202604
),
k AS (
  SELECT ent, s0,
    CASE
      WHEN s0 IS NULL OR s0 <= 0 THEN 'A-otro'
      WHEN c1+c2+c3+c4+c5+c6+c7+c8+c9+c10+c11+c12 = 0 THEN 'A-12'
      WHEN c1+c2+c3+c4+c5+c6+c7+c8+c9+c10+c11 = 0 THEN 'A-11'
      WHEN c1+c2+c3+c4+c5+c6+c7+c8+c9+c10 = 0 THEN 'A-10'
      WHEN c1+c2+c3+c4+c5+c6+c7+c8+c9 = 0 THEN 'A-09'
      WHEN c1+c2+c3+c4+c5+c6+c7+c8 = 0 THEN 'A-08'
      WHEN c1+c2+c3+c4+c5+c6+c7 = 0 THEN 'A-07'
      WHEN c1+c2+c3+c4+c5+c6 = 0 THEN 'A-06'
      WHEN c1+c2+c3+c4+c5 = 0 THEN 'A-05'
      WHEN c1+c2+c3+c4 = 0 THEN 'A-04'
      WHEN c1+c2+c3 = 0 THEN 'A-03'
      WHEN c1+c2 = 0 THEN 'A-02'
      WHEN c1 = 0 THEN 'A-01'
      ELSE 'A-00'
    END AS cat
  FROM b
)

-- ---------- 1. cuantos NULL hay ----------
SELECT '1. NULOS' AS bloque, 'saldo_m0  NULL' AS detalle,
       cast(sum(nl0) AS varchar) || ' de ' || cast(count(*) AS varchar) AS valor FROM b
UNION ALL SELECT '1. NULOS','saldo_m1  NULL',
       cast(sum(nl1) AS varchar) || ' de ' || cast(count(*) AS varchar) FROM b
UNION ALL SELECT '1. NULOS','saldo_m6  NULL',
       cast(sum(nl6) AS varchar) || ' de ' || cast(count(*) AS varchar) FROM b
UNION ALL SELECT '1. NULOS','saldo_m12 NULL',
       cast(sum(nl12) AS varchar) || ' de ' || cast(count(*) AS varchar) FROM b
UNION ALL SELECT '1. NULOS','saldo_m1 = 0 exacto (no NULL)',
       cast(count_if(saldo_m1_es_cero) AS varchar) FROM
       (SELECT cast(saldo_m1 AS double) = 0 AS saldo_m1_es_cero
        FROM disc_monitorian.t_dan_mrm_admbankbpe_altas_rep
        WHERE p_codmes BETWEEN '202601' AND '202604'
          AND cast(codmes AS int) BETWEEN 202601 AND 202604)

UNION ALL

-- ---------- 2. cascada CORREGIDA (coalesce a 0) ----------
SELECT '2. CAT ' || cat, 'IBK', cast(count_if(ent='IBK') AS varchar) FROM k GROUP BY cat
UNION ALL
SELECT '2. CAT ' || cat, 'resto', cast(count_if(ent='resto') AS varchar) FROM k GROUP BY cat

UNION ALL

-- ---------- 3. resumen IBK: ¿alta2 o no? ----------
SELECT '3. RESUMEN IBK', 'dentro de alta2 (A-02..A-12)',
       cast(count_if(ent='IBK' AND cat NOT IN ('A-00','A-01','A-otro')) AS varchar) FROM k
UNION ALL SELECT '3. RESUMEN IBK', 'FUERA de alta2 (A-00/A-01/A-otro)',
       cast(count_if(ent='IBK' AND cat IN ('A-00','A-01','A-otro')) AS varchar) FROM k
UNION ALL SELECT '3. RESUMEN IBK', 'total IBK',
       cast(count_if(ent='IBK') AS varchar) FROM k
ORDER BY 1,2
