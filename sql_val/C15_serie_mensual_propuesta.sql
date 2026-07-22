-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C15_serie_mensual_propuesta.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C15_serie_mensual_propuesta.sql
--   sha256  : 48567e92b9f0   (del cuerpo, sin este encabezado)
--   estado  : VERDE
--   nota    : evolutivo mensual: dirty reciente ~13%, no el 29% pooled (inflado por Impulsa)
-- =====================================================================================
-- =====================================================================================
-- C15_serie_mensual_propuesta.sql | evolutivo MENSUAL clean/dirty de la PROPUESTA FINAL
--
-- Alimenta el grafico del deck de diseno. Definicion CERRADA (giro liberado, C11):
--   SIN BLOQUE = impulsa OR reactiva_puro                 -> fuera de todo ajuste
--   CLEAN  = NO garantizado, flg_monto=1 y 16 exclusiones = 0
--   DIRTY  = NO garantizado, y (flg_monto=0 o alguna de las 16 encendida)
--   16 = 9 RCC + 7 maestras (pnsn, estado_ruc, edad_tit, edad_rl, rrll, esp_tit, esp_cny)
--   giro y ubigeo NO estan en el AND.
--
-- Una fila por mes 202207-202604. Da:
--   n de cada salida · %clean y %dirty SOBRE clean+dirty (la base del ajuste) · RD donde
--   maduro (codmes <= 202505; los meses mas nuevos van sin RD).
--
-- El %clean/%dirty NO necesita maduracion: es ruteo, existe para todo mes. La RD si.
-- Por eso el grafico puede mostrar la COMPOSICION hasta 202604 y la RD hasta 202505.
--
-- ~36 filas. READ-ONLY.
-- =====================================================================================

WITH b AS (
  SELECT cast(codmes AS int) AS codmes,
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
g AS (
  SELECT codmes, y,
         CASE WHEN gar = 1 THEN 'SINBLOQUE'
              WHEN n16 = 0 THEN 'CLEAN'
              ELSE 'DIRTY' END AS bloque
  FROM b
)
SELECT
  codmes,
  count_if(bloque = 'CLEAN')                                   AS n_clean,
  count_if(bloque = 'DIRTY')                                   AS n_dirty,
  count_if(bloque = 'SINBLOQUE')                               AS n_sinbloque,
  count_if(bloque IN ('CLEAN','DIRTY'))                        AS n_ajuste,
  round(100.0 * count_if(bloque = 'CLEAN')
              / nullif(count_if(bloque IN ('CLEAN','DIRTY')), 0), 1)  AS pct_clean,
  round(100.0 * count_if(bloque = 'DIRTY')
              / nullif(count_if(bloque IN ('CLEAN','DIRTY')), 0), 1)  AS pct_dirty,
  -- RD solo donde el mes tiene 12m cerrados
  CASE WHEN codmes <= 202505
       THEN cast(round(100.0 * sum(CASE WHEN bloque='CLEAN' THEN y ELSE 0 END)
                     / nullif(count_if(bloque='CLEAN'),0), 2) AS varchar)
       ELSE 'sin madurar' END                                 AS rd_clean,
  CASE WHEN codmes <= 202505
       THEN cast(round(100.0 * sum(CASE WHEN bloque='DIRTY' THEN y ELSE 0 END)
                     / nullif(count_if(bloque='DIRTY'),0), 2) AS varchar)
       ELSE 'sin madurar' END                                 AS rd_dirty
FROM g
GROUP BY codmes
ORDER BY codmes
