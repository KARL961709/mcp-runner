-- ============================================================================
-- 80. Scoring del stock PP con los coeficientes CONGELADOS de la calibracion
--   Aprende en el perimetro reenganche y aplica sobre el stock completo.
--   La cadena reproduce pd_pit del pipeline con diferencia maxima 4.4e-16.
--   f_t proviene de la serie macro GOBERNADA (e_perm_aws.t_mst_bcrp_rsk.porc_ipc,
--   ticker PN01271PM) y reproduce el f_t desplegado con diferencia 2.3e-07.
--   El driver se reconstruye AQUI sobre el stock: ds_stk_ree_pp_40_drivers solo
--   cubre el perimetro reenganche y dejaria sin segmento al resto.
--   La aritmetica de meses usa DATE_ADD y no resta entera: 202601 menos un mes
--   es 202512, no 202600.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_pp_score_cal
WITH (format = 'PARQUET') AS
WITH ftbl (codmes_mrm, f_t) AS (
  VALUES ('202312', -0.5657409467),
         ('202401', -0.6107771046),
         ('202402', 0.0719021397),
         ('202403', 0.5568083572),
         ('202404', 0.7656840000),
         ('202405', 0.5139711335),
         ('202406', 0.7191775930),
         ('202407', 0.6190848612),
         ('202408', 0.0711119778),
         ('202409', -0.0783144376),
         ('202410', -0.1182428801),
         ('202411', 0.0385011105),
         ('202412', -0.0812810329),
         ('202501', 0.0695605510),
         ('202502', 0.7576818184),
         ('202503', 0.7656840000),
         ('202504', 0.6785319713),
         ('202505', 0.6874022969),
         ('202506', 0.7656840000),
         ('202507', 0.7656840000),
         ('202508', 0.3441683869),
         ('202509', 0.1172661726),
         ('202510', 0.2003893584),
         ('202511', 0.1876904860),
         ('202512', 0.0084792767),
         ('202601', 0.2724082344),
         ('202602', 0.7133369000),
         ('202603', 0.7656840000),
         ('202604', 0.7656840000),
         ('202605', 0.7656840000),
         ('202606', 0.7656840000),
         ('202607', 0.3197562501)
),
stock AS (
  SELECT CAST(v.codmes AS VARCHAR)                                   AS codmes_scr,
         DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(CAST(v.codmes AS VARCHAR), '%Y%m')), '%Y%m') AS codmes_mrm,
         CAST(v.cod_tip_doc AS VARCHAR)                              AS tip_doc,
         CAST(v.key_value AS VARCHAR)                                AS id_value,
         GREATEST(1e-9, LEAST(1.0 - 1e-9, v.pd_comppp_reen_itc))     AS p
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4 v
  WHERE v.pd_comppp_reen_itc IS NOT NULL
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
             WHEN a.sit_lab = 'MIXTO' THEN 'MIXTO'
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
z AS (
  SELECT s.codmes_scr,
         s.codmes_mrm,
         s.tip_doc,
         s.id_value,
         s.p,
         f.f_t,
         CASE WHEN COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') = 'DEPENDIENTE'
              THEN 'DEP' ELSE 'NO DEP' END                        AS tipo_ingreso_dep,
         CAST(CASE WHEN c.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER) AS falla_sin_tipo_ingreso,
         inverse_normal_cdf(0.0, 1.0,
           GREATEST(1e-9, LEAST(1.0 - 1e-9,
             CASE WHEN COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') = 'DEPENDIENTE'
                  THEN 1.0 / (1.0 + exp(-(-1.4235902272 + 1.4307409241 * ln(s.p)
                                          - 0.1167324222 * ln(1.0 - s.p))))
                  ELSE 1.0 / (1.0 + exp(-(-1.8712301291 + 1.1219491911 * ln(s.p)
                                          - 0.5587876582 * ln(1.0 - s.p))))
             END)))
         + CASE WHEN COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') = 'DEPENDIENTE'
                THEN 0.0619737255 ELSE 0.1025757726 END
         + 0.0342617216                                              AS z_ttc
  FROM stock s
  LEFT JOIN cls c
         ON c.id_value = s.id_value AND c.tip_doc = s.tip_doc AND c.codmes = s.codmes_mrm
  LEFT JOIN ftbl f
         ON f.codmes_mrm = s.codmes_mrm
)
SELECT codmes_scr,
       codmes_mrm,
       tip_doc,
       id_value,
       tipo_ingreso_dep,
       falla_sin_tipo_ingreso,
       p                                            AS pd_raw,
       normal_cdf(0.0, 1.0, z_ttc)                  AS pd_ttc,
       CASE WHEN f_t IS NULL THEN NULL ELSE
         GREATEST(1e-4, LEAST(0.9999,
           normal_cdf(0.0, 1.0,
             (z_ttc - sqrt(0.0380301160) * 1.0 * f_t) / sqrt(1.0 - 0.0380301160))))
       END                                          AS pd_pit
FROM z
