-- ============================================================================
-- 50. PD - fuente v4
--   El join va contra codmes_scr, NO contra codmes_mrm + 1: son el mismo mes
--   (codmes_mrm = codmes_scr - 1) y asi el invariante queda a la vista y sin
--   una sola operacion de fecha. Medido: H33 (29 conteos exactos) y H46
--   (flg_reenganche de la v4 reproduce la marca 15226/15226 y 20013/20013).
--   La columna de documento es cod_tip_doc, no tip_doc (H30).
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_50_pd AS
SELECT
  po.codmes_mrm,
  po.tip_doc,
  po.id_value,
  po.codmes_scr,
  v.pd_comppp_reen_itc                                                  AS pd_raw,
  v.score_comppp_reen_itc                                               AS score_raw,
  CAST(v.flg_reenganche AS INTEGER)                                     AS flg_ree_v4,
  CAST(CASE WHEN v.pd_comppp_reen_itc IS NULL THEN 1 ELSE 0 END AS INTEGER) AS cruce_pd,
  CAST(CASE WHEN v.pd_comppp_reen_itc IS NOT NULL
             AND (v.pd_comppp_reen_itc <= 0 OR v.pd_comppp_reen_itc >= 1)
            THEN 1 ELSE 0 END AS INTEGER)                               AS falla_pd_rango
FROM disc_model_owner.ds_stk_ree_pp_10_po po
LEFT JOIN disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4 v
       ON CAST(v.key_value AS VARCHAR)   = po.id_value
      AND CAST(v.cod_tip_doc AS VARCHAR) = po.tip_doc
      AND CAST(v.codmes AS VARCHAR)      = po.codmes_scr
