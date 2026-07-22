-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C14_composicion_reciente.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C14_composicion_reciente.sql
--   sha256  : 1012c46cc7a2   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : clean/dirty sin garantizados + composicion del dirty en calib, ult 3m y mezcla actual
-- =====================================================================================
-- =====================================================================================
-- C14_composicion_reciente.sql | clean/dirty y composicion del dirty, en dos ventanas
--
-- DEFINICION VIGENTE (giro liberado, C11/C12)
--   SIN BLOQUE (garantizados) = impulsa OR reactiva_puro     -> fuera de todo ajuste
--   CLEAN  = NO garantizado, flg_monto=1 y las 16 exclusiones = 0
--   DIRTY  = NO garantizado, y (flg_monto=0 o alguna de las 16 encendida)
--   Las 16 = 9 RCC + 7 maestras (pnsn, estado_ruc, edad_tit, edad_rl, rrll, esp_tit, esp_cny).
--   giro y ubigeo NO estan. (El rotulo "18 exclusiones" incluia los 2 de programa que
--    aca rutean a SIN BLOQUE; el AND real de clean/dirty son 16 + flg_monto.)
--
-- QUE PIDE ESTA CONSULTA
--   1. CLEAN vs DIRTY como % del total EXCLUYENDO garantizados (base = clean + dirty).
--   2. Composicion del dirty por familia (ALCANCE), con RD.
--   Todo en DOS ventanas:
--     CALIB  202207-202505  35 meses, 12m cerrados. RD solida. Es el sustento.
--     REC-RD 202503-202505  ultimos 3 con 12m cerrados. RD, pero regimen deprimido y n chico.
--     REC-MIX 202602-202604 ultimos 3 disponibles. SIN RD (no maduraron). La mezcla ACTUAL.
--
-- ADVERTENCIAS DE LECTURA, no ignorar
--   * 202503-202505 cae en el regimen post-202408: RD global ~4.8% contra ~12.9% en 2022-23.
--     Sus RD NO son comparables con CALIB. El dirty son ~200 obs: muchas familias daran RD 0
--     por baja frecuencia, no por ausencia de riesgo.
--   * ALCANCE suma >100%: un dirty cuenta en toda familia que tenga encendida. Es "a cuantos
--     toca", no "cuantos salen solo por esto".
--   * REC-MIX no tiene RD a proposito: 202602-202604 no cumplieron 12m.
--
-- Poblacion: altas TOP4, flg_ibk=1. ~40 filas. READ-ONLY.
-- =====================================================================================

WITH b AS (
  SELECT cast(codmes AS int) AS codmes,
         cast(target_12m AS double) AS y,
         CASE WHEN coalesce(flg_impulsa,0)=1 OR coalesce(flg_reactiva_puro,0)=1
              THEN 1 ELSE 0 END AS gar,
         CASE WHEN coalesce(flg_monto,0)=0 THEN 1 ELSE 0 END AS f_monto0,
         coalesce(flg_novig_1m_m2,0)+coalesce(flg_novig_12m_m2,0)+coalesce(flg_clasif_m2,0) AS f_perim,
         coalesce(flg_org_castigo_m2,0)+coalesce(flg_org_jud_m2,0)+coalesce(flg_org_refin_m2,0)
       + coalesce(flg_org_reestr_m2,0)+coalesce(flg_org_atraso_m2,0)+coalesce(flg_org_clasif_m2,0) AS f_orig,
         coalesce(flg_pnsn,0)+coalesce(flg_estado_ruc,0) AS f_sunat,
         coalesce(flg_edad_tit,0)+coalesce(flg_edad_rl,0) AS f_edad,
         coalesce(flg_rrll_castigo_m2,0) AS f_rrll,
         coalesce(flg_esp_tit,0)+coalesce(flg_esp_cny,0) AS f_esp
  FROM disc_model_owner.bnbpe_ibk_calib_src
  WHERE flg_ibk = 1 AND top4_entidad = 'TOP4'
    AND cast(codmes AS int) BETWEEN 202207 AND 202604
),
k AS (
  SELECT *,
         f_monto0 + f_perim + f_orig + f_sunat + f_edad + f_rrll + f_esp AS n16,
         CASE WHEN cast(codmes AS int) BETWEEN 202207 AND 202505 THEN 'CALIB 2207-2505'
              WHEN cast(codmes AS int) BETWEEN 202602 AND 202604 THEN 'REC-MIX 2602-2604' END AS w1,
         CASE WHEN cast(codmes AS int) BETWEEN 202503 AND 202505 THEN 'REC-RD 2503-2505' END AS w2
  FROM b
),
kk AS (   -- solo NO garantizados, con bloque
  SELECT *, CASE WHEN n16 = 0 THEN 'CLEAN' ELSE 'DIRTY' END AS bloque
  FROM k WHERE gar = 0
)

-- ------------------------------------------------- 1. CLEAN/DIRTY sobre el total sin garantizados
SELECT '1. CLEAN/DIRTY' AS bloque, ventana AS detalle, bloque AS corte,
       cast(count(*) AS varchar) AS n,
       cast(round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY ventana), 1) AS varchar) || ' %' AS pct,
       CASE WHEN ventana LIKE 'REC-MIX%' THEN 'sin maduracion'
            ELSE cast(round(100.0 * sum(y) / nullif(count(*),0), 2) AS varchar) || ' % RD' END AS rd
FROM (
  SELECT w1 AS ventana, bloque, y FROM kk WHERE w1 IS NOT NULL
  UNION ALL
  SELECT w2, bloque, y FROM kk WHERE w2 IS NOT NULL
) x
GROUP BY ventana, bloque

-- ------------------------------------------------- 2. composicion del dirty · CALIB (sustento)
UNION ALL
SELECT '2. DIRTY · CALIB', fam, 'ALCANCE',
       cast(n AS varchar),
       cast(round(100.0 * n / nullif((SELECT count(*) FROM kk WHERE bloque='DIRTY' AND w1='CALIB 2207-2505'),0),1) AS varchar) || ' % dirty',
       cast(round(100.0 * d / nullif(n,0), 2) AS varchar) || ' % RD'
FROM (
  SELECT 'a monto' fam, count_if(f_monto0>0) n, sum(CASE WHEN f_monto0>0 THEN y ELSE 0 END) d FROM kk WHERE bloque='DIRTY' AND w1='CALIB 2207-2505'
  UNION ALL SELECT 'b rcc perimetro', count_if(f_perim>0), sum(CASE WHEN f_perim>0 THEN y ELSE 0 END) FROM kk WHERE bloque='DIRTY' AND w1='CALIB 2207-2505'
  UNION ALL SELECT 'c rcc origen', count_if(f_orig>0), sum(CASE WHEN f_orig>0 THEN y ELSE 0 END) FROM kk WHERE bloque='DIRTY' AND w1='CALIB 2207-2505'
  UNION ALL SELECT 'd sunat', count_if(f_sunat>0), sum(CASE WHEN f_sunat>0 THEN y ELSE 0 END) FROM kk WHERE bloque='DIRTY' AND w1='CALIB 2207-2505'
  UNION ALL SELECT 'e edad', count_if(f_edad>0), sum(CASE WHEN f_edad>0 THEN y ELSE 0 END) FROM kk WHERE bloque='DIRTY' AND w1='CALIB 2207-2505'
  UNION ALL SELECT 'f rrll', count_if(f_rrll>0), sum(CASE WHEN f_rrll>0 THEN y ELSE 0 END) FROM kk WHERE bloque='DIRTY' AND w1='CALIB 2207-2505'
  UNION ALL SELECT 'g especiales', count_if(f_esp>0), sum(CASE WHEN f_esp>0 THEN y ELSE 0 END) FROM kk WHERE bloque='DIRTY' AND w1='CALIB 2207-2505'
) fa

-- ------------------------------------------------- 3. composicion del dirty · REC-RD (ultimos 3, RD)
UNION ALL
SELECT '3. DIRTY · REC-RD', fam, 'ALCANCE',
       cast(n AS varchar),
       cast(round(100.0 * n / nullif((SELECT count(*) FROM kk WHERE bloque='DIRTY' AND w2 IS NOT NULL),0),1) AS varchar) || ' % dirty',
       cast(round(100.0 * d / nullif(n,0), 2) AS varchar) || ' % RD (n chico)'
FROM (
  SELECT 'a monto' fam, count_if(f_monto0>0) n, sum(CASE WHEN f_monto0>0 THEN y ELSE 0 END) d FROM kk WHERE bloque='DIRTY' AND w2 IS NOT NULL
  UNION ALL SELECT 'b rcc perimetro', count_if(f_perim>0), sum(CASE WHEN f_perim>0 THEN y ELSE 0 END) FROM kk WHERE bloque='DIRTY' AND w2 IS NOT NULL
  UNION ALL SELECT 'c rcc origen', count_if(f_orig>0), sum(CASE WHEN f_orig>0 THEN y ELSE 0 END) FROM kk WHERE bloque='DIRTY' AND w2 IS NOT NULL
  UNION ALL SELECT 'd sunat', count_if(f_sunat>0), sum(CASE WHEN f_sunat>0 THEN y ELSE 0 END) FROM kk WHERE bloque='DIRTY' AND w2 IS NOT NULL
  UNION ALL SELECT 'e edad', count_if(f_edad>0), sum(CASE WHEN f_edad>0 THEN y ELSE 0 END) FROM kk WHERE bloque='DIRTY' AND w2 IS NOT NULL
  UNION ALL SELECT 'f rrll', count_if(f_rrll>0), sum(CASE WHEN f_rrll>0 THEN y ELSE 0 END) FROM kk WHERE bloque='DIRTY' AND w2 IS NOT NULL
  UNION ALL SELECT 'g especiales', count_if(f_esp>0), sum(CASE WHEN f_esp>0 THEN y ELSE 0 END) FROM kk WHERE bloque='DIRTY' AND w2 IS NOT NULL
) fa

-- ------------------------------------------------- 4. composicion del dirty · REC-MIX (mezcla actual, sin RD)
UNION ALL
SELECT '4. DIRTY · REC-MIX', fam, 'ALCANCE',
       cast(n AS varchar),
       cast(round(100.0 * n / nullif((SELECT count(*) FROM kk WHERE bloque='DIRTY' AND w1='REC-MIX 2602-2604'),0),1) AS varchar) || ' % dirty',
       'sin maduracion'
FROM (
  SELECT 'a monto' fam, count_if(f_monto0>0) n FROM kk WHERE bloque='DIRTY' AND w1='REC-MIX 2602-2604'
  UNION ALL SELECT 'b rcc perimetro', count_if(f_perim>0) FROM kk WHERE bloque='DIRTY' AND w1='REC-MIX 2602-2604'
  UNION ALL SELECT 'c rcc origen', count_if(f_orig>0) FROM kk WHERE bloque='DIRTY' AND w1='REC-MIX 2602-2604'
  UNION ALL SELECT 'd sunat', count_if(f_sunat>0) FROM kk WHERE bloque='DIRTY' AND w1='REC-MIX 2602-2604'
  UNION ALL SELECT 'e edad', count_if(f_edad>0) FROM kk WHERE bloque='DIRTY' AND w1='REC-MIX 2602-2604'
  UNION ALL SELECT 'f rrll', count_if(f_rrll>0) FROM kk WHERE bloque='DIRTY' AND w1='REC-MIX 2602-2604'
  UNION ALL SELECT 'g especiales', count_if(f_esp>0) FROM kk WHERE bloque='DIRTY' AND w1='REC-MIX 2602-2604'
) fa

ORDER BY 1, 2, 3
