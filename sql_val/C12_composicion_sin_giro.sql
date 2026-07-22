-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C12_composicion_sin_giro.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C12_composicion_sin_giro.sql
--   sha256  : dc4bf381162d   (del cuerpo, sin este encabezado)
--   estado  : VERDE
--   nota    : giro liberado: clean 8525 (70.7%) / dirty 3528 (29.3%); dirty sube a 13.75% RD
-- =====================================================================================
-- =====================================================================================
-- C12_composicion_sin_giro.sql | la composicion de filtros con GIRO liberado del AND
--
-- DECISION (2026-07-21): flg_giro sale de las exclusiones de APRENDIZAJE. RD historica del
-- giro 4.83% vs clean 8.83% (ratio 0.55x, Fisher p=0.0008), giro <= clean en 4/4 anios, y
-- el scorecard ya lo precifica de mas. Ver C11.
--   flg_calib_18 = flg_monto=1 AND (18 exclusiones = 0)   -- sin flg_giro, sin flg_ubigeo
--   impulsa y reactiva_puro NO estan en el AND: van a SIN BLOQUE, fuera de todo ajuste.
--
-- QUE MIDE
--   Bloque 1: el embudo con las TRES salidas bajo la definicion NUEVA (18) contra la
--             vieja (19). Cuanto crece el clean, cuanto encoge el dirty.
--   Bloque 2: composicion del dirty NUEVO. giro ya no esta; que filtro queda dominante.
--   Bloque 3: los que MIGRAN por liberar giro — GIRO solo -> clean. Su RD confirma que
--             no ensucian el bloque.
--   Bloque 4: por personeria, para el sustento.
--
-- Ventana 202207-202505, 12m cerrados. Altas TOP4, flg_ibk=1.
-- ~35 filas. READ-ONLY.
-- =====================================================================================

WITH b AS (
  SELECT cast(codmes AS int) AS codmes, personeria,
         cast(target_12m AS double) AS y,
         coalesce(flg_impulsa,0)       AS f_imp,
         coalesce(flg_reactiva_puro,0) AS f_rea,
         coalesce(flg_giro,0)          AS f_giro,
         -- las 18 que quedan en el AND nuevo (sin giro, sin ubigeo)
         (CASE WHEN coalesce(flg_monto,0)=0 THEN 1 ELSE 0 END)
       + coalesce(flg_novig_1m_m2,0) + coalesce(flg_novig_12m_m2,0) + coalesce(flg_clasif_m2,0)
       + coalesce(flg_org_castigo_m2,0) + coalesce(flg_org_jud_m2,0) + coalesce(flg_org_refin_m2,0)
       + coalesce(flg_org_reestr_m2,0) + coalesce(flg_org_atraso_m2,0) + coalesce(flg_org_clasif_m2,0)
       + coalesce(flg_pnsn,0) + coalesce(flg_estado_ruc,0)
       + coalesce(flg_edad_tit,0) + coalesce(flg_edad_rl,0) + coalesce(flg_rrll_castigo_m2,0)
       + coalesce(flg_esp_tit,0) + coalesce(flg_esp_cny,0)          AS n18,
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
    AND cast(codmes AS int) BETWEEN 202207 AND 202505
),
g AS (
  SELECT *,
         CASE WHEN f_imp = 1 OR f_rea = 1 THEN 'SIN BLOQUE'
              WHEN n18 = 0 THEN 'CLEAN'
              ELSE 'DIRTY' END AS grupo_nuevo,
         -- salida vieja (giro dentro del AND): para el antes/despues
         CASE WHEN f_imp = 1 OR f_rea = 1 THEN 'SIN BLOQUE'
              WHEN n18 = 0 AND f_giro = 0 THEN 'CLEAN'
              ELSE 'DIRTY' END AS grupo_viejo
  FROM b
)

-- ------------------------------------------------- 1. antes / despues
SELECT '1. ANTES (19 excl)' AS bloque, grupo_viejo AS detalle, 'TODOS' AS corte,
       cast(count(*) AS varchar) AS n,
       cast(round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS varchar) || ' %' AS pct,
       cast(round(100.0 * avg(y), 2) AS varchar) || ' % RD' AS rd
FROM g GROUP BY grupo_viejo
UNION ALL
SELECT '2. DESPUES (18 excl)', grupo_nuevo, 'TODOS',
       cast(count(*) AS varchar),
       cast(round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS varchar) || ' %',
       cast(round(100.0 * avg(y), 2) AS varchar) || ' % RD'
FROM g GROUP BY grupo_nuevo

-- ------------------------------------------------- 3. composicion del dirty NUEVO
-- ALCANCE de cada familia sobre el dirty nuevo (sin giro). Suma >100%: se solapan.
UNION ALL
SELECT '3. DIRTY sin giro', fam, 'ALCANCE',
       cast(n AS varchar),
       cast(round(100.0 * n / nullif((SELECT count(*) FROM g WHERE grupo_nuevo='DIRTY'),0), 1) AS varchar) || ' % del dirty',
       cast(round(100.0 * d / nullif(n,0), 2) AS varchar) || ' % RD'
FROM (
  SELECT 'a monto (flg_monto=0)' AS fam, count_if(f_monto0>0) AS n, sum(CASE WHEN f_monto0>0 THEN y ELSE 0 END) AS d FROM g WHERE grupo_nuevo='DIRTY'
  UNION ALL SELECT 'b rcc perimetro', count_if(f_perim>0), sum(CASE WHEN f_perim>0 THEN y ELSE 0 END) FROM g WHERE grupo_nuevo='DIRTY'
  UNION ALL SELECT 'c rcc origen', count_if(f_orig>0), sum(CASE WHEN f_orig>0 THEN y ELSE 0 END) FROM g WHERE grupo_nuevo='DIRTY'
  UNION ALL SELECT 'd sunat (pnsn/ruc)', count_if(f_sunat>0), sum(CASE WHEN f_sunat>0 THEN y ELSE 0 END) FROM g WHERE grupo_nuevo='DIRTY'
  UNION ALL SELECT 'e edad tit/rl', count_if(f_edad>0), sum(CASE WHEN f_edad>0 THEN y ELSE 0 END) FROM g WHERE grupo_nuevo='DIRTY'
  UNION ALL SELECT 'f rrll castigo', count_if(f_rrll>0), sum(CASE WHEN f_rrll>0 THEN y ELSE 0 END) FROM g WHERE grupo_nuevo='DIRTY'
  UNION ALL SELECT 'g especiales', count_if(f_esp>0), sum(CASE WHEN f_esp>0 THEN y ELSE 0 END) FROM g WHERE grupo_nuevo='DIRTY'
) fams

-- ------------------------------------------------- 4. los que MIGRAN por liberar giro
UNION ALL
SELECT '4. MIGRAN (giro->clean)', personeria, 'GIRO solo',
       cast(count(*) AS varchar),
       cast(round(100.0 * avg(y), 2) AS varchar) || ' % RD',
       'entran al clean'
FROM g WHERE f_giro = 1 AND n18 = 0 AND f_imp = 0 AND f_rea = 0
GROUP BY personeria

-- ------------------------------------------------- 5. clean antes/despues por personeria
UNION ALL
SELECT '5. CLEAN x PERS', personeria, 'antes 19',
       cast(count_if(grupo_viejo='CLEAN') AS varchar),
       cast(round(100.0 * sum(CASE WHEN grupo_viejo='CLEAN' THEN y ELSE 0 END)
                / nullif(count_if(grupo_viejo='CLEAN'),0), 2) AS varchar) || ' % RD', ''
FROM g GROUP BY personeria
UNION ALL
SELECT '5. CLEAN x PERS', personeria, 'despues 18',
       cast(count_if(grupo_nuevo='CLEAN') AS varchar),
       cast(round(100.0 * sum(CASE WHEN grupo_nuevo='CLEAN' THEN y ELSE 0 END)
                / nullif(count_if(grupo_nuevo='CLEAN'),0), 2) AS varchar) || ' % RD', ''
FROM g GROUP BY personeria

ORDER BY 1, 2, 3
