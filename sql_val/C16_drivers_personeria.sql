-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C16_drivers_personeria.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C16_drivers_personeria.sql
--   sha256  : 801710dc5b93   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : los DRIVERS PN/PJ x bloque para el slide base; pooled y ultimos 3 meses
-- =====================================================================================
-- =====================================================================================
-- C16_drivers_personeria.sql | los DRIVERS: PN / PJ (y el bloque clean/dirty dentro)
--
-- Para el slide base. Los DRIVERS de segmentacion de la calibracion son la personeria:
--   PNN (persona natural)  · beta-cal
--   PJJ (persona juridica) · logit-cal
-- clean/dirty es el BLOQUE (tratamiento), ORTOGONAL a la personeria. Cada coeficiente
-- vive en la celda personeria x bloque.
--
-- Da la grilla PN/PJ x clean/dirty con n, malos y RD, en dos ventanas:
--   CALIB  202207-202505  (pooled)
--   REC    202503-202505  (ultimos 3 madurados) — para el titular ~13% dirty
-- Base = clean + dirty (sin garantizados). Definicion final: 16 exclusiones, giro liberado.
--
-- ~14 filas. READ-ONLY.
-- =====================================================================================

WITH b AS (
  SELECT cast(codmes AS int) AS codmes, personeria,
         cast(target_12m AS double) AS y,
         CASE WHEN coalesce(flg_impulsa,0)=1 OR coalesce(flg_reactiva_puro,0)=1 THEN 1 ELSE 0 END AS gar,
         (CASE WHEN coalesce(flg_monto,0)=0 THEN 1 ELSE 0 END)
       + coalesce(flg_novig_1m_m2,0) + coalesce(flg_novig_12m_m2,0) + coalesce(flg_clasif_m2,0)
       + coalesce(flg_org_castigo_m2,0) + coalesce(flg_org_jud_m2,0) + coalesce(flg_org_refin_m2,0)
       + coalesce(flg_org_reestr_m2,0) + coalesce(flg_org_atraso_m2,0) + coalesce(flg_org_clasif_m2,0)
       + coalesce(flg_pnsn,0) + coalesce(flg_estado_ruc,0)
       + coalesce(flg_edad_tit,0) + coalesce(flg_edad_rl,0) + coalesce(flg_rrll_castigo_m2,0)
       + coalesce(flg_esp_tit,0) + coalesce(flg_esp_cny,0)          AS n16
  FROM disc_model_owner.bnbpe_ibk_calib_src
  WHERE flg_ibk = 1 AND top4_entidad = 'TOP4'
    AND cast(codmes AS int) BETWEEN 202207 AND 202505
),
k AS (
  SELECT codmes, personeria, y,
         CASE WHEN gar = 1 THEN 'SINBLOQUE' WHEN n16 = 0 THEN 'CLEAN' ELSE 'DIRTY' END AS bloque,
         CASE WHEN codmes BETWEEN 202503 AND 202505 THEN 1 ELSE 0 END AS rec
  FROM b
)

-- 1 · driver PN/PJ (base ajuste) — POOLED
SELECT '1. DRIVER · CALIB' AS bloque, personeria AS driver, 'base ajuste' AS corte,
       cast(count(*) AS varchar) AS n,
       cast(sum(y) AS varchar) AS malos,
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %' AS rd
FROM k WHERE bloque IN ('CLEAN','DIRTY') GROUP BY personeria

-- 2 · grilla personeria x bloque — POOLED
UNION ALL
SELECT '2. PERS x BLOQUE · CALIB', personeria || ' · ' || bloque, 'pooled',
       cast(count(*) AS varchar), cast(sum(y) AS varchar),
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM k WHERE bloque IN ('CLEAN','DIRTY') GROUP BY personeria, bloque

-- 3 · driver PN/PJ — ULTIMOS 3 MESES (para el titular)
UNION ALL
SELECT '3. DRIVER · REC 2503-2505', personeria, 'base ajuste',
       cast(count(*) AS varchar), cast(sum(y) AS varchar),
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM k WHERE bloque IN ('CLEAN','DIRTY') AND rec = 1 GROUP BY personeria

-- 4 · clean/dirty REC por personeria
UNION ALL
SELECT '4. PERS x BLOQUE · REC', personeria || ' · ' || bloque, 'ult 3m',
       cast(count(*) AS varchar), cast(sum(y) AS varchar),
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM k WHERE bloque IN ('CLEAN','DIRTY') AND rec = 1 GROUP BY personeria, bloque

-- 5 · totales de control
UNION ALL
SELECT '5. CONTROL', 'base ajuste / sin bloque', 'pooled',
       cast(count_if(bloque IN ('CLEAN','DIRTY')) AS varchar),
       cast(count_if(bloque = 'SINBLOQUE') AS varchar),
       cast(round(100.0 * count_if(bloque='DIRTY') / nullif(count_if(bloque IN ('CLEAN','DIRTY')),0),1) AS varchar) || ' % dirty'
FROM k

ORDER BY 1, 2
