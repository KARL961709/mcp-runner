-- ============================================================================
-- 80. Scoring del stock PP con los coeficientes CONGELADOS de la calibracion
--   Aprende en el perimetro reenganche (marca, hasta 202604; ajuste hasta 202506
--   por madurez) y APLICA sobre el stock completo, que llega a 202607.
--   La cadena reproduce pd_pit del pipeline con diferencia maxima 4.4e-16.
--
--   ANTES DE EJECUTAR hay que completar ftbl con el f_t de cada mes a puntuar.
--   El calendario vigente termina en 202604: los meses 202605-202607 exigen
--   extender la serie macro y recalcular f_t. Los NULL de abajo son deliberados:
--   sin f_t la fila devuelve pd_pit nulo y el mes queda sin puntuar, en lugar de
--   producir un numero con un factor inventado.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_pp_score_cal
WITH (format = 'PARQUET') AS
WITH ftbl (codmes, f_t) AS (
  VALUES ('202605', CAST(NULL AS DOUBLE)),
         ('202606', CAST(NULL AS DOUBLE)),
         ('202607', CAST(NULL AS DOUBLE))
),
d AS (
  SELECT v.codmes,
         v.cod_tip_doc,
         v.key_value,
         GREATEST(1e-9, LEAST(1.0 - 1e-9, v.pd_comppp_reen_itc)) AS p,
         CASE WHEN s.tipo_ingreso_dep IS NULL THEN 'NO DEP' ELSE s.tipo_ingreso_dep END AS seg,
         CASE WHEN s.tipo_ingreso_dep IS NULL THEN 1 ELSE 0 END  AS falla_driver
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4 v
  LEFT JOIN disc_model_owner.ds_stk_ree_pp_40_drivers s
         ON CAST(s.id_value AS VARCHAR)   = CAST(v.key_value AS VARCHAR)
        AND CAST(s.tip_doc AS VARCHAR)    = CAST(v.cod_tip_doc AS VARCHAR)
        AND CAST(s.codmes_mrm AS VARCHAR) = CAST(CAST(v.codmes AS INTEGER) - 1 AS VARCHAR)
  WHERE v.pd_comppp_reen_itc IS NOT NULL
),
z AS (
  SELECT d.*,
         f.f_t,
         inverse_normal_cdf(0.0, 1.0,
           GREATEST(1e-9, LEAST(1.0 - 1e-9,
             CASE WHEN d.seg = 'DEP'
                  THEN 1.0 / (1.0 + exp(-(-1.4235902272 + 1.4307409241 * ln(d.p)
                                          - 0.1167324222 * ln(1.0 - d.p))))
                  ELSE 1.0 / (1.0 + exp(-(-1.8712301291 + 1.1219491911 * ln(d.p)
                                          - 0.5587876582 * ln(1.0 - d.p))))
             END)))
         + CASE WHEN d.seg = 'DEP' THEN 0.0619737255 ELSE 0.1025757726 END
         + 0.0342617216                                            AS z_ttc
  FROM d
  LEFT JOIN ftbl f ON f.codmes = CAST(d.codmes AS VARCHAR)
)
SELECT codmes,
       cod_tip_doc,
       key_value,
       seg                                          AS tipo_ingreso_dep,
       falla_driver,
       p                                            AS pd_raw,
       normal_cdf(0.0, 1.0, z_ttc)                  AS pd_ttc,
       CASE WHEN f_t IS NULL THEN NULL ELSE
         GREATEST(1e-4, LEAST(0.9999,
           normal_cdf(0.0, 1.0,
             (z_ttc - sqrt(0.0380301160) * 1.0 * f_t) / sqrt(1.0 - 0.0380301160))))
       END                                          AS pd_pit
FROM z
