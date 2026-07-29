-- ============================================================================
-- 80. PD calibrada del stock PP  --  formato de 47_score_vcadmbnk_v7.sql
--   Lee la tabla de score y los drivers YA construidos. No reconstruye nada.
--   El factor macro se DERIVA de la tabla gobernada e_perm_aws.t_mst_bcrp_rsk
--   (porc_ipc, ticker PN01271PM) en vez de escribirse como literal.
--   Reproduce pd_pit del pipeline con diferencia maxima 4.4e-16.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_80_score
WITH (format = 'PARQUET') AS
WITH ftbl AS (
  SELECT cod_mes AS codmes_mrm,
         GREATEST(-1.130850, LEAST(0.765684,
           (-1.7250030205 - sqrt(1.0 - 0.0380301160) * (-1.9001957962 + 0.6583423568 * x_t))
           / sqrt(0.0380301160) + 0.19111262)) AS f_t
  FROM (
    SELECT cod_mes,
           AVG(porc_ipc) OVER (ORDER BY cod_mes ROWS BETWEEN 10 PRECEDING AND 5 PRECEDING) AS x_t
    FROM e_perm_aws.t_mst_bcrp_rsk
    WHERE cod_mes >= '201801'
  ) m
  WHERE x_t IS NOT NULL
),
d AS (
  SELECT CAST(v.codmes AS VARCHAR) AS codmes,
         DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(CAST(v.codmes AS VARCHAR), '%Y%m')), '%Y%m') AS codmes_mrm,
         CAST(v.cod_tip_doc AS VARCHAR) AS tip_doc,
         v.key_value,
         GREATEST(1e-9, LEAST(1.0 - 1e-9, AVG(v.pd_comppp_reen_itc))) AS p,
         MAX(v.score_comppp_reen_itc) AS puntuacion
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4 v
  WHERE v.pd_comppp_reen_itc IS NOT NULL
  GROUP BY CAST(v.codmes AS VARCHAR), CAST(v.cod_tip_doc AS VARCHAR), v.key_value
),
zc AS (
  SELECT d.codmes, d.codmes_mrm, d.tip_doc, d.key_value, d.p, d.puntuacion, f.f_t,
         COALESCE(dr.tipo_ingreso_dep, 'NO DEP') AS tipo_ingreso,
         (inverse_normal_cdf(0.0, 1.0, GREATEST(1e-9, LEAST(1.0 - 1e-9,
            CASE WHEN COALESCE(dr.tipo_ingreso_dep, 'NO DEP') = 'DEP'
                 THEN 1.0/(1.0+exp(-((-1.4235902272) + (1.4307409241)*ln(d.p) - (0.1167324222)*ln(1.0-d.p))))
                 ELSE 1.0/(1.0+exp(-((-1.8712301291) + (1.1219491911)*ln(d.p) - (0.5587876582)*ln(1.0-d.p))))
            END)))
          + (CASE WHEN COALESCE(dr.tipo_ingreso_dep, 'NO DEP') = 'DEP'
                  THEN 0.0619737255 ELSE 0.1025757726 END)
          + (0.0342617216)) AS z_ttc
  FROM d
  LEFT JOIN disc_model_owner.ds_stk_ree_pp_40_drivers dr
         ON dr.id_value = d.key_value AND dr.tip_doc = d.tip_doc AND dr.codmes_mrm = d.codmes_mrm
  LEFT JOIN ftbl f ON f.codmes_mrm = d.codmes_mrm
),
fin AS (
  SELECT zc.*,
         GREATEST(1e-4, LEAST(0.9999,
           normal_cdf(0.0, 1.0,
             (z_ttc - sqrt(0.0380301160) * 1.0 * f_t) / sqrt(1.0 - 0.0380301160)))) AS pcal
  FROM zc
)
SELECT codmes,
       tip_doc,
       key_value,
       p                AS probabilidad,
       puntuacion,
       tipo_ingreso     AS trf_tipo_ingreso,
       pcal             AS prob_modelo_cal,
       CAST(round((1.0 - pcal) * 1000) AS INTEGER) AS puntuacion_cal
FROM fin
