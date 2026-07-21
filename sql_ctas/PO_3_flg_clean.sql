-- =====================================================================================
-- PO_3_flg_clean.sql | ETAPA 3 de 3 — el AND de las dos etapas
--
-- ESCRIBE: crea disc_model_owner.b46029_po_flg_clean
--
-- Regla de q4_maestro_calib_src.sql (flg_calib_m2), con DOS desviaciones documentadas:
--   * SIN flg_monto: depende del monto desembolsado y no existe antes del alta. En
--     altas pesa poco de todos modos — F1 midio 33 clientes de 848 dirty, un 3.9%.
--   * flg_impulsa BACKWARD [m0-12, m0] en vez de forward [m0, m0+12]: el original mira
--     hacia adelante y no es implementable ex-ante. B1 confirmo que ya no entran
--     clientes nuevos al programa (unidades por mes desde 202504), asi que ambas
--     definiciones convergen para cohortes actuales.
--   * flg_ubigeo se calcula aparte y NO entra (LIBERADO, decision 2026-07-02).
--
-- flg_clean sale 0 o 1 SIEMPRE: los LEFT JOIN llevan coalesce(...,0), asi que un
-- cliente sin fila en alguna etapa se trata como sin knockout = clean.
--
-- Si ya existe: DROP TABLE disc_model_owner.b46029_po_flg_clean
-- =====================================================================================
CREATE TABLE disc_model_owner.b46029_po_flg_clean
WITH (format='PARQUET', parquet_compression='SNAPPY') AS

SELECT
  r.codmes, r.tip_doc, r.key_value,

  coalesce(r.flg_novig_1m_m2,0)    AS flg_novig_1m_m2,
  coalesce(r.flg_novig_12m_m2,0)   AS flg_novig_12m_m2,
  coalesce(r.flg_clasif_m2,0)      AS flg_clasif_m2,
  coalesce(r.flg_org_castigo_m2,0) AS flg_org_castigo_m2,
  coalesce(r.flg_org_jud_m2,0)     AS flg_org_jud_m2,
  coalesce(r.flg_org_refin_m2,0)   AS flg_org_refin_m2,
  coalesce(r.flg_org_reestr_m2,0)  AS flg_org_reestr_m2,
  coalesce(r.flg_org_atraso_m2,0)  AS flg_org_atraso_m2,
  coalesce(r.flg_org_clasif_m2,0)  AS flg_org_clasif_m2,
  coalesce(r.flg_impulsa_bwd,0)    AS flg_impulsa_bwd,
  coalesce(r.flg_reactiva_puro,0)  AS flg_reactiva_puro,
  coalesce(m.flg_pnsn,0)           AS flg_pnsn,
  coalesce(m.flg_estado_ruc,0)     AS flg_estado_ruc,
  coalesce(m.flg_giro,0)           AS flg_giro,
  coalesce(m.flg_edad_tit,0)       AS flg_edad_tit,
  coalesce(m.flg_edad_rl,0)        AS flg_edad_rl,
  coalesce(m.flg_rrll_castigo_m2,0) AS flg_rrll_castigo_m2,
  coalesce(m.flg_esp_tit,0)        AS flg_esp_tit,
  coalesce(m.flg_esp_cny,0)        AS flg_esp_cny,

  CASE WHEN coalesce(r.flg_novig_1m_m2,0)=0    AND coalesce(r.flg_novig_12m_m2,0)=0
        AND coalesce(r.flg_clasif_m2,0)=0      AND coalesce(r.flg_org_castigo_m2,0)=0
        AND coalesce(r.flg_org_jud_m2,0)=0     AND coalesce(r.flg_org_refin_m2,0)=0
        AND coalesce(r.flg_org_reestr_m2,0)=0  AND coalesce(r.flg_org_atraso_m2,0)=0
        AND coalesce(r.flg_org_clasif_m2,0)=0
        AND coalesce(r.flg_impulsa_bwd,0)=0    AND coalesce(r.flg_reactiva_puro,0)=0
        AND coalesce(m.flg_pnsn,0)=0           AND coalesce(m.flg_estado_ruc,0)=0
        AND coalesce(m.flg_giro,0)=0           AND coalesce(m.flg_edad_tit,0)=0
        AND coalesce(m.flg_edad_rl,0)=0        AND coalesce(m.flg_rrll_castigo_m2,0)=0
        AND coalesce(m.flg_esp_tit,0)=0        AND coalesce(m.flg_esp_cny,0)=0
       THEN 1 ELSE 0 END AS flg_clean

FROM disc_model_owner.b46029_po_flg_rcc r
LEFT JOIN disc_model_owner.b46029_po_flg_maestras m
  ON m.codmes=r.codmes AND m.tip_doc=r.tip_doc AND m.key_value=r.key_value
