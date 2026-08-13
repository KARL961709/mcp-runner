-- ============================================================================
-- V13. EL NODO APORTA POR ENCIMA DE LA PD O SOLO REDESCUBRE EL SCORE
--   scan: __T___cal, entidad 00002, flg_calib = 1 y flg_clean = 1
--   ancla: el nodo no usa el score en ninguna de sus 20 ramas. Si dentro de una misma
--          banda de pd_raw los tres nodos dan la misma rd, el score ya lo capturo y el
--          nodo no entra a la calibracion. Si siguen separando, el modelo tiene sesgo
--          sistematico por nodo y hay que segmentarlo o reportarlo
--   ratio_obs_pred es lo que la calibracion tiene que corregir: si difiere por nodo
--          dentro de la misma banda, un solo calibrador no alcanza
-- ============================================================================
WITH b AS (
    SELECT nodo_final,
           target_12m,
           pd_raw,
           ntile(5) OVER (ORDER BY pd_raw)                                              AS banda
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE entidad = '00002'
      AND flg_calib = 1
      AND flg_clean = 1
      AND pd_raw IS NOT NULL
)
SELECT CASE WHEN GROUPING(banda) = 1 THEN 'T.total' ELSE CAST(banda AS VARCHAR) END     AS banda_pd,
       CASE WHEN GROUPING(nodo_final) = 1 THEN 'T.total' ELSE nodo_final END            AS nodo,
       count(*)                                                                         AS n,
       sum(target_12m)                                                                  AS n_malo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       round(100.0 * avg(pd_raw), 4)                                                    AS pd_raw_media,
       round(avg(CAST(target_12m AS DOUBLE)) / nullif(avg(pd_raw), 0), 4)               AS ratio_obs_pred,
       round(100.0 * min(pd_raw), 4)                                                    AS pd_min,
       round(100.0 * max(pd_raw), 4)                                                    AS pd_max
FROM b
GROUP BY GROUPING SETS ((banda, nodo_final), (banda), (nodo_final), ())
ORDER BY banda_pd, nodo
LIMIT 40
