-- ============================================================================
-- 80. Scoring del stock PP con la calibracion de Comportamental Reenganche
--   Estructura tomada de 47_score_vcadmbnk_v7.sql. Unica diferencia de fondo:
--   el factor macro NO se escribe a mano sino que se DERIVA de la tabla
--   gobernada e_perm_aws.t_mst_bcrp_rsk (columna porc_ipc, ticker PN01271PM).
--   Asi el f_t no queda congelado en un literal que envejece.
--
--   Cadena: pd_raw -> BetaCal por segmento -> probit -> delta segmento -> delta_0
--           -> Vasicek(f_t, rho, lambda=1) -> pd calibrada
--   Verificado: reproduce pd_pit del pipeline con diferencia maxima 4.4e-16,
--   y el f_t derivado reproduce el desplegado con 2.3e-07.
--
--   f_t = clip( (Phi^-1(LRA) - sqrt(1-rho)*(b0 + b1*x_t))/sqrt(rho) - mu , cap )
--   con x_t = media de porc_ipc sobre los meses t-10 a t-5. El paso por
--   Phi y Phi^-1 se cancela algebraicamente (verificado, 3.4e-15).
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_80_score
WITH (format = 'PARQUET') AS
WITH macro AS (
  SELECT cod_mes,
         AVG(porc_ipc) OVER (ORDER BY cod_mes ROWS BETWEEN 10 PRECEDING AND 5 PRECEDING) AS x_t
  FROM e_perm_aws.t_mst_bcrp_rsk
  WHERE cod_mes >= '201801'
),
ftbl AS (
  SELECT cod_mes AS codmes_mrm,
         GREATEST(-1.130850, LEAST(0.765684,
           (-1.7250030205 - sqrt(1.0 - 0.0380301160) * (-1.9001957962 + 0.6583423568 * x_t))
           / sqrt(0.0380301160) - (-0.19111262)
         )) AS f_t
  FROM macro
  WHERE x_t IS NOT NULL
),
d AS (
  SELECT CAST(v.codmes AS VARCHAR)                                   AS codmes,
         DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(CAST(v.codmes AS VARCHAR), '%Y%m')), '%Y%m') AS codmes_mrm,
         CAST(v.cod_tip_doc AS VARCHAR)                              AS tip_doc,
         v.key_value,
         GREATEST(1e-9, LEAST(1.0 - 1e-9, AVG(v.pd_comppp_reen_itc))) AS p,
         MAX(v.score_comppp_reen_itc)                                AS puntuacion
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4 v
  WHERE v.pd_comppp_reen_itc IS NOT NULL
  GROUP BY CAST(v.codmes AS VARCHAR), CAST(v.cod_tip_doc AS VARCHAR), v.key_value
),
cls AS (
  SELECT tip_doc, id_value, codmes, tipo_ingreso
  FROM (
    SELECT CAST(a.tip_doc AS VARCHAR) AS tip_doc,
           SUBSTR(a.subject_id, 3)    AS id_value,
           CAST(a.periodo AS VARCHAR) AS codmes,
           CASE
             WHEN a.sit_lab = 'DEPENDIENTE'
              AND a.fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'DEPENDIENTE'
             WHEN a.sit_lab = 'DEPENDIENTE' THEN 'MIXTO'
             WHEN a.sit_lab = 'MIXTO'       THEN 'MIXTO'
             ELSE 'INDEPENDIENTE'
           END AS tipo_ingreso,
           ROW_NUMBER() OVER (
             PARTITION BY SUBSTR(a.subject_id, 3), a.periodo, CAST(a.tip_doc AS VARCHAR)
             ORDER BY a.p_fecinformacion DESC, a.subject_id ASC) AS rn
    FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir a
    WHERE CAST(a.numcarga AS INT) = 1
  ) r
  WHERE rn = 1
),
zc AS (
  SELECT d.*,
         f.f_t,
         CASE WHEN COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') = 'DEPENDIENTE'
              THEN 'DEP' ELSE 'NO DEP' END                          AS tipo_ingreso,
         CAST(CASE WHEN c.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER) AS falla_sin_tipo_ingreso,
         (inverse_normal_cdf(0.0, 1.0, GREATEST(1e-9, LEAST(1.0 - 1e-9,
            CASE WHEN COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') = 'DEPENDIENTE'
                 THEN 1.0/(1.0+exp(-((-1.4235902272) + (1.4307409241)*ln(d.p) - (0.1167324222)*ln(1.0-d.p))))
                 ELSE 1.0/(1.0+exp(-((-1.8712301291) + (1.1219491911)*ln(d.p) - (0.5587876582)*ln(1.0-d.p))))
            END)))
          + (CASE WHEN COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') = 'DEPENDIENTE'
                  THEN 0.0619737255 ELSE 0.1025757726 END)
          + (0.0342617216))                                            AS z_ttc
  FROM d
  LEFT JOIN cls c
         ON c.id_value = d.key_value AND c.tip_doc = d.tip_doc AND c.codmes = d.codmes_mrm
  LEFT JOIN ftbl f
         ON f.codmes_mrm = d.codmes_mrm
),
fin AS (
  SELECT zc.*,
         normal_cdf(0.0, 1.0, z_ttc) AS pd_ttc,
         CASE WHEN f_t IS NULL THEN NULL ELSE
           GREATEST(1e-4, LEAST(0.9999,
             normal_cdf(0.0, 1.0,
               (z_ttc - sqrt(0.0380301160) * 1.0000 * f_t) / sqrt(1.0 - 0.0380301160))))
         END                         AS pd_pit
  FROM zc
)
SELECT codmes,
       codmes_mrm,
       tip_doc,
       key_value,
       p                        AS probabilidad,
       puntuacion,
       tipo_ingreso             AS trf_tipo_ingreso,
       falla_sin_tipo_ingreso   AS trf_falla_sin_tipo_ingreso,
       f_t                      AS trf_f_t,
       pd_ttc                   AS prob_modelo_ttc,
       CAST(round((1.0 - pd_ttc) * 1000) AS INTEGER) AS puntuacion_ttc,
       pd_pit                   AS prob_modelo_cal,
       CAST(round((1.0 - pd_pit) * 1000) AS INTEGER) AS puntuacion_cal
FROM fin
