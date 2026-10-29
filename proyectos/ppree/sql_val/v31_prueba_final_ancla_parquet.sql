-- ============================================================================
-- v31. LA PRUEBA FINAL DEL ANCLA DEL PARQUET, en dos numeros.
--   El parquet trae pd media = 33.7059 pct en la cohorte 202301 (medido local).
--   Aca se pide la pd de la fuente para ESOS MISMOS clientes en los dos meses
--   candidatos. El que empate dice que ancla uso el export.
--     cod_mes = 202301  -> mes con mes   (50_pd nuevo)
--     cod_mes = 202302  -> M+1           (50_pd viejo)
--   Dos meses consecutivos de la fuente difieren medio punto o mas (v23), asi
--   que el empate a cuatro decimales no puede ser casualidad.
--   Se incluye 202212 para dejar contado si la fuente tiene ese mes.
-- ============================================================================
WITH pob AS (
  SELECT CAST(tip_doc AS VARCHAR) AS tip_doc,
         CAST(id_value AS VARCHAR) AS id_value
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE codmes_mrm = '202301'
    AND flg_scope_ree = 1
)
SELECT CAST(v.cod_mes AS VARCHAR)                    AS cod_mes,
       COUNT(*)                                      AS n,
       ROUND(100.0 * AVG(v.prob_modelo), 4)          AS pd_media_pct,
       ROUND(MIN(v.prob_modelo), 8)                  AS pd_min,
       ROUND(MAX(v.prob_modelo), 8)                  AS pd_max
FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610 v
JOIN pob p
  ON CAST(v.key_value AS VARCHAR)   = p.id_value
 AND CAST(v.cod_tip_doc AS VARCHAR) = p.tip_doc
WHERE CAST(v.cod_mes AS VARCHAR) IN ('202212', '202301', '202302')
  AND v.prob_modelo IS NOT NULL
GROUP BY CAST(v.cod_mes AS VARCHAR)
ORDER BY 1
