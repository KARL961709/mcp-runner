-- ============================================================================
-- 80. PD calibrada del stock PP  --  formato de 47_score_vcadmbnk_v7.sql
--
-- TODO PARTE DE FUENTES MADRE. No se lee ninguna tabla intermedia del pipeline.
--   score              disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4
--   situacion laboral  e_perm_aws.ds_rtd_rskvol_cas_ingr_ir   -> tipo_ingreso
--   cuenta sueldo      e_perm_aws.t_rsk_cta_sueldo            -> flg_cs
--   macro              e_perm_aws.t_mst_bcrp_rsk (porc_ipc)   -> f_t
--
-- Los drivers se derivan con la MISMA expresion de 40_drivers.sql, copiada
-- literal y no re-tipeada. Unico cambio de alcance: la poblacion es el stock
-- a puntuar en vez del perimetro reenganche.
--
-- codmes_drv = codmes - 1 es el mes donde se leen los drivers. Coincide con el
-- codmes_mrm del maestro de calibracion, pero se nombra distinto porque aqui no
-- hay PO: es solo el rezago con el que la calibracion aprendio la pareja
-- pd_raw(codmes) contra driver(codmes-1), segun 50_pd.sql y H33.
-- PENDIENTE DE MEDIR (c6): H33 conteo ese rezago sobre la tabla hermana
-- ..._itc_reen_reprocesov4, no sobre esta. Aqui se hereda por analogia.
--
-- Reglas de cruce que imponen las fuentes:
--   situacion laboral no tiene key_value: la llave es SUBSTR(subject_id, 3)
--   solo numcarga = 1, dedupe por p_fecinformacion descendente
--   cuenta sueldo castea tipdoc dos veces porque los catalogos no comparten
--     padding, y su periodo va un mes por detras del de situacion laboral
--   la aritmetica de meses usa DATE_ADD: 202601 menos un mes es 202512
--
-- El factor macro se deriva de la serie gobernada, no se escribe como literal:
--   f_t = clip( (Phi^-1(LRA) - sqrt(1-rho)*(b0 + b1*x_t))/sqrt(rho) - mu )
--   con x_t = media de porc_ipc sobre t-10 a t-5 (el lag5 + ma6 del modelo).
--
-- Verificado: la cadena reproduce pd_pit del pipeline con diferencia 4.4e-16
-- y el f_t derivado reproduce el desplegado con 2.3e-07.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_80_score
WITH (format = 'PARQUET') AS
WITH ftbl AS (
  SELECT cod_mes AS codmes_drv,
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
         DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(CAST(v.codmes AS VARCHAR), '%Y%m')), '%Y%m') AS codmes_drv,
         CAST(v.cod_tip_doc AS VARCHAR) AS tip_doc,
         CAST(v.key_value AS VARCHAR) AS id_value,
         GREATEST(1e-9, LEAST(1.0 - 1e-9, AVG(v.pd_comppp_reen_itc))) AS p,
         MAX(v.score_comppp_reen_itc) AS puntuacion
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4 v
  WHERE v.pd_comppp_reen_itc IS NOT NULL
  GROUP BY CAST(v.codmes AS VARCHAR), CAST(v.cod_tip_doc AS VARCHAR), CAST(v.key_value AS VARCHAR)
),
po AS (
  SELECT DISTINCT codmes_drv, tip_doc, id_value FROM d
),
cls AS (
  SELECT tip_doc, id_value, codmes, tipo_ingreso
  FROM (
    SELECT CAST(a.tip_doc AS VARCHAR) AS tip_doc,
           SUBSTR(a.subject_id, 3)    AS id_value,
           CAST(a.periodo AS VARCHAR) AS codmes,
           CASE
             WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'DEPENDIENTE'
             WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'MIXTO'
             WHEN a.sit_lab = 'MIXTO' THEN 'MIXTO'
             ELSE 'INDEPENDIENTE'
           END AS tipo_ingreso,
           ROW_NUMBER() OVER (
             PARTITION BY SUBSTR(a.subject_id, 3), a.periodo, CAST(a.tip_doc AS VARCHAR)
             ORDER BY a.p_fecinformacion DESC, a.subject_id ASC) AS rn
    FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir a
    INNER JOIN po b
      ON CAST(a.periodo AS VARCHAR) = b.codmes_drv
     AND SUBSTR(a.subject_id, 3) = b.id_value
    WHERE CAST(a.numcarga AS INT) = 1
  ) r
  WHERE rn = 1
),
cs AS (
  SELECT
    CAST(codmes AS VARCHAR)                          AS codmes,
    CAST(key_value AS VARCHAR)                       AS id_value,
    CAST(CAST(tipdoc AS INTEGER) AS VARCHAR)         AS tip_doc,
    MAX(CAST(flg_cs_riesgos AS INTEGER))             AS flg_cs
  FROM e_perm_aws.t_rsk_cta_sueldo
  GROUP BY 1, 2, 3
),
zc AS (
  SELECT d.codmes, d.codmes_drv, d.tip_doc, d.id_value, d.p, d.puntuacion, f.f_t,
         COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') AS tipo_ingreso,
         CASE WHEN COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') = 'DEPENDIENTE' THEN 'DEP' ELSE 'NO DEP' END AS tipo_ingreso_dep,
         CASE
           WHEN s.id_value IS NULL THEN 'SIN_DATO'
           WHEN COALESCE(s.flg_cs, 0) = 1 THEN 'CS'
           ELSE 'NO_CS'
         END AS flg_cs_estado,
         CAST(CASE WHEN c.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER) AS falla_sin_tipo_ingreso,
         CAST(CASE WHEN s.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER) AS falla_sin_cta_sueldo,
         (inverse_normal_cdf(0.0, 1.0, GREATEST(1e-9, LEAST(1.0 - 1e-9,
            CASE WHEN COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') = 'DEPENDIENTE'
                 THEN 1.0/(1.0+exp(-((-1.4235902272) + (1.4307409241)*ln(d.p) - (0.1167324222)*ln(1.0-d.p))))
                 ELSE 1.0/(1.0+exp(-((-1.8712301291) + (1.1219491911)*ln(d.p) - (0.5587876582)*ln(1.0-d.p))))
            END)))
          + (CASE WHEN COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') = 'DEPENDIENTE'
                  THEN 0.0619737255 ELSE 0.1025757726 END)
          + (0.0342617216)) AS z_ttc
  FROM d
  LEFT JOIN cls c
         ON c.id_value = d.id_value AND c.tip_doc = d.tip_doc AND c.codmes = d.codmes_drv
  LEFT JOIN cs s
         ON s.id_value = d.id_value AND s.tip_doc = d.tip_doc
        AND s.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(d.codmes_drv, '%Y%m')), '%Y%m')
  LEFT JOIN ftbl f ON f.codmes_drv = d.codmes_drv
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
       id_value                AS key_value,
       p                       AS probabilidad,
       puntuacion,
       tipo_ingreso            AS trf_tipo_ingreso,
       tipo_ingreso_dep        AS trf_tipo_ingreso_dep,
       flg_cs_estado           AS trf_flg_cs_estado,
       falla_sin_tipo_ingreso  AS trf_falla_sin_tipo_ingreso,
       falla_sin_cta_sueldo    AS trf_falla_sin_cta_sueldo,
       f_t                     AS trf_f_t,
       pcal                    AS prob_modelo_cal,
       CAST(round((1.0 - pcal) * 1000) AS INTEGER) AS puntuacion_cal
FROM fin
