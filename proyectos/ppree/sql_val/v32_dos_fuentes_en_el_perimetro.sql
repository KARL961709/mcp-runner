-- ============================================================================
-- v32. Las dos fuentes, pero RESTRINGIDAS AL PERIMETRO REENGANCHE.
--   v27 midio que reen_v4 y cal_2023 coinciden en el 98.6 pct del STOCK y
--   discrepan en ~1.4 pct (1,500-2,100 clientes por mes). El perimetro
--   reenganche es ~1,500 de 125,000, o sea 1.2 pct: del mismo orden.
--   Si los discrepantes SON los de reenganche, entonces los dos parquets
--   pueden leer el MISMO mes y aun asi coincidir en solo 0.20 pct, y ese
--   0.20 pct deja de ser evidencia de cambio de ancla.
--   Esto lo mide: mismo cruce de v27 pero solo sobre el perimetro.
-- ============================================================================
WITH pob AS (
  SELECT DISTINCT
         CAST(codmes_scr AS VARCHAR) AS mes_scr,
         CAST(codmes_mrm AS VARCHAR) AS mes_mrm,
         CAST(tip_doc AS VARCHAR)    AS tip_doc,
         CAST(id_value AS VARCHAR)   AS id_value
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE flg_scope_ree = 1
    AND codmes_mrm BETWEEN '202401' AND '202505'
),
v AS (
  SELECT CAST(codmes AS VARCHAR)      AS mes,
         CAST(cod_tip_doc AS VARCHAR) AS tip_doc,
         CAST(key_value AS VARCHAR)   AS id_value,
         CAST(pd_comppp_reen_itc AS DOUBLE) AS pd_v
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
  WHERE pd_comppp_reen_itc IS NOT NULL
),
n AS (
  SELECT CAST(cod_mes AS VARCHAR)     AS mes,
         CAST(cod_tip_doc AS VARCHAR) AS tip_doc,
         CAST(key_value AS VARCHAR)   AS id_value,
         CAST(prob_modelo AS DOUBLE)  AS pd_n
  FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610
  WHERE prob_modelo IS NOT NULL
)
SELECT 'perimetro, las dos en mes_scr' AS prueba,
       COUNT(*)                                                        AS n_pob,
       COUNT(v.pd_v)                                                   AS n_reen_v4,
       COUNT(n.pd_n)                                                   AS n_cal_2023,
       SUM(CASE WHEN abs(v.pd_v - n.pd_n) < 1e-12 THEN 1 ELSE 0 END)   AS n_identica,
       ROUND(100.0 * AVG(v.pd_v), 4)                                   AS pd_reen_v4_pct,
       ROUND(100.0 * AVG(n.pd_n), 4)                                   AS pd_cal_2023_pct,
       ROUND(MAX(ABS(v.pd_v - n.pd_n)), 8)                             AS max_dif
  FROM pob p
  LEFT JOIN v ON v.mes = p.mes_scr AND v.tip_doc = p.tip_doc AND v.id_value = p.id_value
  LEFT JOIN n ON n.mes = p.mes_scr AND n.tip_doc = p.tip_doc AND n.id_value = p.id_value
UNION ALL
SELECT 'perimetro, las dos en mes_mrm',
       COUNT(*), COUNT(v.pd_v), COUNT(n.pd_n),
       SUM(CASE WHEN abs(v.pd_v - n.pd_n) < 1e-12 THEN 1 ELSE 0 END),
       ROUND(100.0 * AVG(v.pd_v), 4), ROUND(100.0 * AVG(n.pd_n), 4),
       ROUND(MAX(ABS(v.pd_v - n.pd_n)), 8)
  FROM pob p
  LEFT JOIN v ON v.mes = p.mes_mrm AND v.tip_doc = p.tip_doc AND v.id_value = p.id_value
  LEFT JOIN n ON n.mes = p.mes_mrm AND n.tip_doc = p.tip_doc AND n.id_value = p.id_value
ORDER BY 1
