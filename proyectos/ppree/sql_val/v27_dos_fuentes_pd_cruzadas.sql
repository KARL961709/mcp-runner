-- ============================================================================
-- v27. LAS DOS FUENTES CANDIDATAS de pd_raw, cruzadas en su grano comun
--   El master vigente es compatible con las dos: su pd arranca en 202212 con
--   cobertura 100 pct y las dos fuentes arrancan en 202301, asi que el ancla +1
--   explica el dato con cualquiera. Esto lo zanja: si la pd coincide, da igual
--   cual alimento el parquet, es el mismo numero.
--   Join por el grano declarado del 50_pd: (mes, key_value, cod_tip_doc).
-- ============================================================================
WITH v AS (
  SELECT CAST(codmes AS VARCHAR)              AS mes,
         CAST(key_value AS VARCHAR)           AS kv,
         CAST(cod_tip_doc AS VARCHAR)         AS td,
         CAST(pd_comppp_reen_itc AS DOUBLE)   AS pd_v,
         CAST(score_comppp_reen_itc AS DOUBLE) AS sc_v
    FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
   WHERE CAST(codmes AS VARCHAR) >= '202501'
     AND pd_comppp_reen_itc IS NOT NULL
),
n AS (
  SELECT CAST(cod_mes AS VARCHAR)             AS mes,
         CAST(key_value AS VARCHAR)           AS kv,
         CAST(cod_tip_doc AS VARCHAR)         AS td,
         CAST(prob_modelo AS DOUBLE)          AS pd_n,
         CAST(puntuacion AS DOUBLE)           AS sc_n
    FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610
   WHERE CAST(cod_mes AS VARCHAR) >= '202501'
     AND prob_modelo IS NOT NULL
)
SELECT
  COALESCE(v.mes, n.mes)                                                 AS mes,
  COUNT(v.kv)                                                            AS n_reen_v4,
  COUNT(n.kv)                                                            AS n_cal_2023,
  COUNT(CASE WHEN v.kv IS NOT NULL AND n.kv IS NOT NULL THEN 1 END)      AS n_cruce,
  COUNT(CASE WHEN v.kv IS NOT NULL AND n.kv IS NULL THEN 1 END)          AS solo_reen_v4,
  COUNT(CASE WHEN v.kv IS NULL AND n.kv IS NOT NULL THEN 1 END)          AS solo_cal_2023,
  ROUND(MAX(ABS(v.pd_v - n.pd_n)), 12)                                   AS max_dif_pd,
  ROUND(AVG(ABS(v.pd_v - n.pd_n)), 12)                                   AS avg_dif_pd,
  COUNT(CASE WHEN ABS(v.pd_v - n.pd_n) > 1e-9 THEN 1 END)                AS n_pd_distinta,
  ROUND(MAX(ABS(v.sc_v - n.sc_n)), 6)                                    AS max_dif_score,
  ROUND(100.0 * AVG(v.pd_v), 4)                                          AS pd_media_reen_pct,
  ROUND(100.0 * AVG(n.pd_n), 4)                                          AS pd_media_cal_pct
FROM v
FULL OUTER JOIN n
  ON  n.mes = v.mes
  AND n.kv  = v.kv
  AND n.td  = v.td
GROUP BY COALESCE(v.mes, n.mes)
ORDER BY 1
