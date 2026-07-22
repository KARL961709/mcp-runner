-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C17_cosecha_normal.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C17_cosecha_normal.sql
--   sha256  : a62f0c4e7b82   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : volumen reciente 2602-2604 + RD sobre cosecha normal (pre-Impulsa vs post); para el deck
-- =====================================================================================
-- =====================================================================================
-- C17_cosecha_normal.sql | volumen reciente + RD sobre COSECHA NORMAL (no distorsionada)
--
-- Dos tipos de resultado, dos ventanas distintas, a proposito:
--   VOLUMEN / COMPOSICION  -> no necesita rd12. Se toma lo MAS RECIENTE (calib_src llega
--                             a 202604): ventana 202602-202604.
--   RD (tasa de default)   -> necesita rd12 cerrado Y una cosecha NORMAL, sin la distorsion
--                             de garantizados. 2503-2505 NO sirve: SIN BLOQUE ~20-25% y la
--                             base queda sesgada por seleccion (los buenos se fueron a
--                             SIN BLOQUE via Impulsa forward).
--
-- Este SQL muestra las candidatas de cosecha normal con su % de garantizados, para elegir:
--   A · pre-Impulsa   202207-202303  (garantizados 2-8%, la mas "normal", matura, con eventos)
--   B · post-Impulsa  202501-202505  (garantizados ~20%, reciente pero pocos eventos)
-- Cada una con la grilla PN/PJ x clean/dirty (n, def, RD).
--
-- Definicion final: 16 exclusiones, giro liberado. Base = clean + dirty (sin garantizados).
-- ~30 filas. READ-ONLY.
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
    AND cast(codmes AS int) BETWEEN 202207 AND 202604
),
k AS (
  SELECT codmes, personeria, y, gar,
         CASE WHEN gar = 1 THEN 'SINBLOQUE' WHEN n16 = 0 THEN 'CLEAN' ELSE 'DIRTY' END AS bloque,
         CASE WHEN codmes BETWEEN 202602 AND 202604 THEN 'VOL'
              WHEN codmes BETWEEN 202207 AND 202303 THEN 'A_pre'
              WHEN codmes BETWEEN 202501 AND 202505 THEN 'B_post' END AS win
  FROM b
)

-- 1 · VOLUMEN 202602-202604 (lo mas reciente, sin RD): driver x bloque
SELECT '1. VOLUMEN 2602-2604' AS bloque, personeria || ' · ' || bloque AS celda,
       cast(count(*) AS varchar) AS n,
       cast(round(100.0 * count(*)
            / nullif(sum(count(*)) OVER (), 0), 1) AS varchar) || ' %' AS pct_base,
       'sin rd (no maduro)' AS rd
FROM k WHERE win = 'VOL' AND bloque IN ('CLEAN','DIRTY')
GROUP BY personeria, bloque

-- 1b · garantizados en la ventana de volumen (para declararlo)
UNION ALL
SELECT '1. VOLUMEN 2602-2604', 'z · garantizados / total', 'contexto',
       cast(count_if(bloque='SINBLOQUE') AS varchar),
       cast(round(100.0 * count_if(bloque='SINBLOQUE') / nullif(count(*),0),1) AS varchar) || ' % del total', ''
FROM k WHERE win = 'VOL'

-- 2 · garantizados por cosecha candidata (para elegir la NORMAL)
UNION ALL
SELECT '2. GARANTIZADOS x cosecha',
       CASE win WHEN 'A_pre' THEN 'A · pre-Impulsa 2207-2303' ELSE 'B · post 2501-2505' END,
       'sin bloque %',
       cast(count_if(bloque='SINBLOQUE') AS varchar),
       cast(round(100.0 * count_if(bloque='SINBLOQUE') / nullif(count(*),0),1) AS varchar) || ' %',
       'normal si es bajo'
FROM k WHERE win IN ('A_pre','B_post') GROUP BY win

-- 3 · RD grilla PN/PJ x bloque — COSECHA A (pre-Impulsa)
UNION ALL
SELECT '3. RD · A pre-Impulsa', personeria || ' · ' || bloque, 'rd12',
       cast(count(*) AS varchar),
       cast(sum(y) AS varchar) || ' def',
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM k WHERE win = 'A_pre' AND bloque IN ('CLEAN','DIRTY') GROUP BY personeria, bloque

-- 4 · RD grilla PN/PJ x bloque — COSECHA B (post-Impulsa)
UNION ALL
SELECT '4. RD · B post-Impulsa', personeria || ' · ' || bloque, 'rd12',
       cast(count(*) AS varchar),
       cast(sum(y) AS varchar) || ' def',
       cast(round(100.0 * avg(y), 2) AS varchar) || ' %'
FROM k WHERE win = 'B_post' AND bloque IN ('CLEAN','DIRTY') GROUP BY personeria, bloque

ORDER BY 1, 2
