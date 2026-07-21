-- =====================================================================================
-- ORIGEN BPE PD · V2 · BUILD (crea tablas)
--   archivo : 30_flg_clean.sql
--   origen  : ~\mcp-runner\sql_ctas\PO_3_flg_clean.sql
--   sha256  : 6821450c51fa   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : depende de 10 y 20
-- =====================================================================================
-- =====================================================================================
-- PO_3_flg_clean.sql | ETAPA 3 de 3 — el AND de las dos etapas
--
-- ESCRIBE: crea disc_model_owner.b46029_po_flg_clean
--
-- Regla de q4_maestro_calib_src.sql (flg_calib_m2), con TRES desviaciones documentadas:
--
--   * IMPULSA Y REACTIVA_PURO NO ENTRAN AL AND  (decision del usuario, 2026-07-21)
--     Se siguen calculando y se exponen como columnas, pero NO deciden clean/dirty.
--     Por que: son marcadores de PROGRAMA, no de riesgo. Su papel legitimo es excluir
--     esas operaciones del APRENDIZAJE de los coeficientes — y ahi se mantienen fuera,
--     tanto en clean (flg_calib_m2 los saca) como en dirty (q3b los saca). Usarlos
--     ademas para enrutar en produccion mezcla dos cosas distintas: un cliente Impulsa
--     con RCC y maestras limpias caia en dirty solo por el programa, y recibia
--     coeficientes ajustados sobre una poblacion que no lo incluia.
--     El propio q3b lo dice: el grupo dirty son "excluidos por politica/perfil, NO por
--     programa". F1 midio 376 de 848 dirty que existian solo por Impulsa.
--     Con el cambio: impulsa + RCC sucio sigue siendo dirty (por el RCC, que es lo
--     correcto); impulsa + todo limpio pasa a clean.
--     OJO: esto hace que flg_clean de la PO NO sea flg_calib_m2. Son variables
--     distintas a proposito.
--
--   * SIN flg_monto: depende del monto desembolsado y no existe antes del alta. En
--     altas pesa poco de todos modos — F1 midio 33 clientes de 848 dirty, un 3.9%.
--
--   * flg_ubigeo se calcula aparte y NO entra (LIBERADO, decision 2026-07-02).
--
-- flg_impulsa_bwd se calcula BACKWARD [m0-12, m0] en vez de forward [m0, m0+12]: el
-- original mira hacia adelante y no es implementable ex-ante. B1 confirmo que ya no
-- entran clientes nuevos (unidades por mes desde 202504).
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

  -- 17 condiciones de RIESGO. flg_impulsa_bwd y flg_reactiva_puro quedan FUERA a
  -- proposito: son marcadores de programa y su papel es excluir del aprendizaje de los
  -- coeficientes, no enrutar en produccion. Se exponen arriba como columnas.
  CASE WHEN coalesce(r.flg_novig_1m_m2,0)=0    AND coalesce(r.flg_novig_12m_m2,0)=0
        AND coalesce(r.flg_clasif_m2,0)=0      AND coalesce(r.flg_org_castigo_m2,0)=0
        AND coalesce(r.flg_org_jud_m2,0)=0     AND coalesce(r.flg_org_refin_m2,0)=0
        AND coalesce(r.flg_org_reestr_m2,0)=0  AND coalesce(r.flg_org_atraso_m2,0)=0
        AND coalesce(r.flg_org_clasif_m2,0)=0
        AND coalesce(m.flg_pnsn,0)=0           AND coalesce(m.flg_estado_ruc,0)=0
        AND coalesce(m.flg_giro,0)=0           AND coalesce(m.flg_edad_tit,0)=0
        AND coalesce(m.flg_edad_rl,0)=0        AND coalesce(m.flg_rrll_castigo_m2,0)=0
        AND coalesce(m.flg_esp_tit,0)=0        AND coalesce(m.flg_esp_cny,0)=0
       THEN 1 ELSE 0 END AS flg_clean

FROM disc_model_owner.b46029_po_flg_rcc r
LEFT JOIN disc_model_owner.b46029_po_flg_maestras m
  ON m.codmes=r.codmes AND m.tip_doc=r.tip_doc AND m.key_value=r.key_value
