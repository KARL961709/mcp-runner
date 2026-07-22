-- =====================================================================================
-- ORIGEN BPE PD · V2 · VALIDACION (read-only)
--   archivo : C_calibra/C18_familias_cosecha.sql
--   origen  : ~\Documents\2026\GDM\Origen_BPE_PD_V2\_src\C18_familias_cosecha.sql
--   sha256  : ee445920b03b   (del cuerpo, sin este encabezado)
--   estado  : ROJO
--   nota    : RD por familia sobre cosecha normal 2207-2303, para homologar la slide de exclusiones
-- =====================================================================================
-- =====================================================================================
-- C18_familias_cosecha.sql | RD por familia de exclusion sobre la COSECHA NORMAL
--
-- Para que la slide de exclusiones use la MISMA ventana que la slide base: la cosecha
-- normal pre-Impulsa 202207-202303 (garantizados 2.6%, rd12 cerrado, sin distorsion).
-- Antes la RD por familia estaba sobre 202207-202505 (contaminada). Esto la homologa.
--
-- ALCANCE por familia (un dirty cuenta en cada familia encendida; suma >100%).
-- Referencia = RD del CLEAN en la misma cosecha.
-- Definicion final: 16 exclusiones, giro liberado.
--
-- ~10 filas. READ-ONLY.
-- =====================================================================================

WITH b AS (
  SELECT cast(target_12m AS double) AS y,
         CASE WHEN coalesce(flg_impulsa,0)=1 OR coalesce(flg_reactiva_puro,0)=1 THEN 1 ELSE 0 END AS gar,
         CASE WHEN coalesce(flg_monto,0)=0 THEN 1 ELSE 0 END AS f_monto0,
         coalesce(flg_novig_1m_m2,0)+coalesce(flg_novig_12m_m2,0)+coalesce(flg_clasif_m2,0) AS f_perim,
         coalesce(flg_org_castigo_m2,0)+coalesce(flg_org_jud_m2,0)+coalesce(flg_org_refin_m2,0)
       + coalesce(flg_org_reestr_m2,0)+coalesce(flg_org_atraso_m2,0)+coalesce(flg_org_clasif_m2,0) AS f_orig,
         coalesce(flg_pnsn,0)+coalesce(flg_estado_ruc,0) AS f_sunat,
         coalesce(flg_edad_tit,0)+coalesce(flg_edad_rl,0) AS f_edad,
         coalesce(flg_rrll_castigo_m2,0) AS f_rrll,
         coalesce(flg_esp_tit,0)+coalesce(flg_esp_cny,0) AS f_esp,
         coalesce(flg_giro,0) AS f_giro,
         (CASE WHEN coalesce(flg_monto,0)=0 THEN 1 ELSE 0 END)
       + coalesce(flg_novig_1m_m2,0)+coalesce(flg_novig_12m_m2,0)+coalesce(flg_clasif_m2,0)
       + coalesce(flg_org_castigo_m2,0)+coalesce(flg_org_jud_m2,0)+coalesce(flg_org_refin_m2,0)
       + coalesce(flg_org_reestr_m2,0)+coalesce(flg_org_atraso_m2,0)+coalesce(flg_org_clasif_m2,0)
       + coalesce(flg_pnsn,0)+coalesce(flg_estado_ruc,0)
       + coalesce(flg_edad_tit,0)+coalesce(flg_edad_rl,0)+coalesce(flg_rrll_castigo_m2,0)
       + coalesce(flg_esp_tit,0)+coalesce(flg_esp_cny,0) AS n16
  FROM disc_model_owner.bnbpe_ibk_calib_src
  WHERE flg_ibk = 1 AND top4_entidad = 'TOP4'
    AND cast(codmes AS int) BETWEEN 202207 AND 202303
),
d AS (SELECT * FROM b WHERE gar = 0)   -- base ajuste (sin garantizados)

SELECT 'a · CLEAN (referencia)' AS familia,
       cast(count_if(n16=0) AS varchar) AS n,
       cast(sum(CASE WHEN n16=0 THEN y ELSE 0 END) AS varchar) AS def,
       cast(round(100.0*sum(CASE WHEN n16=0 THEN y ELSE 0 END)/nullif(count_if(n16=0),0),2) AS varchar)||' %' AS rd
FROM d
UNION ALL SELECT 'b · monto (flg_monto=0)', cast(count_if(f_monto0>0) AS varchar), cast(sum(CASE WHEN f_monto0>0 THEN y ELSE 0 END) AS varchar), cast(round(100.0*sum(CASE WHEN f_monto0>0 THEN y ELSE 0 END)/nullif(count_if(f_monto0>0),0),2) AS varchar)||' %' FROM d WHERE n16>0
UNION ALL SELECT 'c · rcc perimetro', cast(count_if(f_perim>0) AS varchar), cast(sum(CASE WHEN f_perim>0 THEN y ELSE 0 END) AS varchar), cast(round(100.0*sum(CASE WHEN f_perim>0 THEN y ELSE 0 END)/nullif(count_if(f_perim>0),0),2) AS varchar)||' %' FROM d WHERE n16>0
UNION ALL SELECT 'd · rcc origen', cast(count_if(f_orig>0) AS varchar), cast(sum(CASE WHEN f_orig>0 THEN y ELSE 0 END) AS varchar), cast(round(100.0*sum(CASE WHEN f_orig>0 THEN y ELSE 0 END)/nullif(count_if(f_orig>0),0),2) AS varchar)||' %' FROM d WHERE n16>0
UNION ALL SELECT 'e · sunat (pnsn/ruc)', cast(count_if(f_sunat>0) AS varchar), cast(sum(CASE WHEN f_sunat>0 THEN y ELSE 0 END) AS varchar), cast(round(100.0*sum(CASE WHEN f_sunat>0 THEN y ELSE 0 END)/nullif(count_if(f_sunat>0),0),2) AS varchar)||' %' FROM d WHERE n16>0
UNION ALL SELECT 'f · edad', cast(count_if(f_edad>0) AS varchar), cast(sum(CASE WHEN f_edad>0 THEN y ELSE 0 END) AS varchar), cast(round(100.0*sum(CASE WHEN f_edad>0 THEN y ELSE 0 END)/nullif(count_if(f_edad>0),0),2) AS varchar)||' %' FROM d WHERE n16>0
UNION ALL SELECT 'g · rrll castigo', cast(count_if(f_rrll>0) AS varchar), cast(sum(CASE WHEN f_rrll>0 THEN y ELSE 0 END) AS varchar), cast(round(100.0*sum(CASE WHEN f_rrll>0 THEN y ELSE 0 END)/nullif(count_if(f_rrll>0),0),2) AS varchar)||' %' FROM d WHERE n16>0
UNION ALL SELECT 'h · especiales', cast(count_if(f_esp>0) AS varchar), cast(sum(CASE WHEN f_esp>0 THEN y ELSE 0 END) AS varchar), cast(round(100.0*sum(CASE WHEN f_esp>0 THEN y ELSE 0 END)/nullif(count_if(f_esp>0),0),2) AS varchar)||' %' FROM d WHERE n16>0
UNION ALL SELECT 'i · giro (liberado)', cast(count_if(f_giro>0) AS varchar), cast(sum(CASE WHEN f_giro>0 THEN y ELSE 0 END) AS varchar), cast(round(100.0*sum(CASE WHEN f_giro>0 THEN y ELSE 0 END)/nullif(count_if(f_giro>0),0),2) AS varchar)||' %' FROM d
ORDER BY 1
