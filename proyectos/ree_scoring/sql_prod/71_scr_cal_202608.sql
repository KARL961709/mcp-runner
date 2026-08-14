-- ============================================================================
-- 71. SCORE CALIBRADO SOBRE LA v5 - corte 202608
--   scan: disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov5 (32 meses, 4,341,213)
--   ancla: los coeficientes son los de ENTREGA_REE_FINAL, sin reajustar ninguno.
--          calibracion_beta.json, vasicek_rho.json, lra.json, macro_model.json,
--          pit_transformation.json
--
--   CADENA:
--     pd_raw -> BetaCal(tipo_ingreso_dep) -> corrimiento probit(seg) -> delta_0
--            -> Vasicek PIT(f_t del mes) -> prob_modelo_cal -> puntuacion_cal
--     rho 0.038030115964094044   lambda 1   LRA 0.04226346409008948
--     delta_0 0.034261721611022956   SIN driver adicional (selected_drivers = [])
--     SIN margen de conservadurismo: el MoC nunca se cableo al pipeline
--
--   REPRODUCE LA VIGENTE. Medido antes de escribir esto: la misma cadena en modo
--   lectura reproduce scr_stk_ree_pp_cal_202607 en los 31 meses con diferencias
--   de 1e-10 a 4,5e-9 en PD. Los 8 meses con residuo mayor son exactamente los 8
--   en que f_t toca el tope, 8 de 8 contra 0 de 23 en el resto: es la precision
--   del literal del cap. La puntuacion usa ROUND y no FLOOR porque con FLOOR los
--   promedios habrian diferido en medio punto y dieron identicos a 13 digitos.
--
--   EL MES QUE AGREGA. La vigente tiene 4,208,408 filas hasta 202607, que es la
--   v5 menos su ultimo mes. Este corte suma 202608 y queda en 4,341,213.
--
--   EL FACTOR NO VIENE DE UNA TABLA DE VALORES. Se calcula desde la fuente
--   gobernada e_perm_aws.t_mst_bcrp_rsk, columna porc_ipc, ticker BCRP PN01271PM,
--   que reproduce el parquet de feature engineering con diferencia maxima 0.0
--   sobre los 40 meses comunes. La ventana es la media de T-10 a T-5, o sea el
--   factor de T queda determinado por IPC hasta T-5.
--   El calendario es PROPIO y no las filas del IPC: la serie termina en 202606 y
--   sin calendario no existiria fila para 202607, que es justo el mes que 202608
--   necesita. Y el guard cuenta valores NO NULOS: con COUNT(*) daria 6 aunque los
--   seis IPC fueran nulos y saldria un factor inventado.
--   El centrado y el capeo van CONGELADOS porque son de la calibracion, medidos
--   sobre los 54 meses de la ventana de la LRA. Recalcularlos contra el dato del
--   mes dejaria el calendario a la deriva.
--
--   ANCLAS TEMPORALES. codmes de la v5 es el mes del archivo de scoring y
--   describe el stock del mes anterior, asi que codmes_mrm = codmes - 1 por
--   calendario. El factor y el tipo de ingreso se anclan en codmes_mrm y la
--   cuenta sueldo en codmes_mrm - 1, igual que 40_drivers.sql.
--
--   DEP VALIDADO. Se resuelve con GROUP BY y MAX en vez de ROW_NUMBER por
--   recencia. Sobre el dato medido son identicos: hay exactamente un registro por
--   cliente y periodo, con lo que n_degradado dio 0 en los cuatro meses sondeados.
--   Difieren solo si un mes trajera varios, y ahi MAX dice "tiene registro
--   validado, es DEP", que es el criterio, mientras el orden por fecha diria "el
--   ultimo gana", que no lo es. Ademas MAX no puede producir fan-out.
--
--   TIPOS. Casteados explicito contra lo que devuelva 14b sobre la vigente.
-- ============================================================================
CREATE TABLE disc_model_owner.scr_stk_ree_pp_cal_202608 AS
WITH
cal_meses AS (
  SELECT DATE_FORMAT(m, '%Y%m')                                                   AS cm
    FROM UNNEST(sequence(DATE '2018-01-01', DATE '2027-12-01',
                         INTERVAL '1' MONTH)) AS t(m)),
ipc AS (
  SELECT c.cm,
         MAX(CAST(b.porc_ipc AS DOUBLE))                                          AS ipc
    FROM cal_meses c
    LEFT JOIN e_perm_aws.t_mst_bcrp_rsk b
      ON CAST(b.cod_mes AS VARCHAR) = c.cm
   GROUP BY 1),
mac AS (
  SELECT cm,
         AVG(ipc)   OVER (ORDER BY cm ROWS BETWEEN 10 PRECEDING AND 5 PRECEDING)  AS x,
         COUNT(ipc) OVER (ORDER BY cm ROWS BETWEEN 10 PRECEDING AND 5 PRECEDING)  AS n_vent
    FROM ipc),
ft AS (
  SELECT cm                                                                       AS codmes_mrm,
         GREATEST(LEAST(
           (inverse_normal_cdf(0.0, 1.0, 0.04226346409008948)
             - sqrt(1.0 - 0.038030115964094044)
               * (-1.900195796163702 + 0.6583423568236846 * x))
           / sqrt(0.038030115964094044)
           + 0.19111262350586136
         , 0.7656842281878757), -1.1308495593693428)                              AS f_t
    FROM mac
   WHERE n_vent = 6),
cls AS (
  SELECT SUBSTR(subject_id, 3)                                                    AS id_value,
         CAST(tip_doc AS VARCHAR)                                                 AS tip_doc,
         CAST(periodo AS VARCHAR)                                                 AS codmes_mrm,
         MAX(CASE WHEN sit_lab = 'DEPENDIENTE'
                   AND fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP')
                  THEN 1 ELSE 0 END)                                              AS dep_validado,
         MAX(CASE WHEN sit_lab = 'MIXTO'
                    OR (sit_lab = 'DEPENDIENTE'
                        AND fuente IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP'))
                  THEN 1 ELSE 0 END)                                              AS mixto
    FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
   WHERE CAST(numcarga AS INT) = 1
     AND CAST(periodo AS VARCHAR) >= '202312'
   GROUP BY 1, 2, 3),
cs AS (
  SELECT CAST(codmes AS VARCHAR)                                                  AS codmes,
         CAST(key_value AS VARCHAR)                                               AS id_value,
         CAST(CAST(tipdoc AS INTEGER) AS VARCHAR)                                 AS tip_doc,
         MAX(CAST(flg_cs_riesgos AS INTEGER))                                     AS flg_cs
    FROM e_perm_aws.t_rsk_cta_sueldo
   GROUP BY 1, 2, 3),
v5 AS (
  SELECT CAST(codmes AS VARCHAR)                                                  AS codmes,
         DATE_FORMAT(DATE_ADD('month', -1,
                     DATE_PARSE(CAST(codmes AS VARCHAR), '%Y%m')), '%Y%m')        AS codmes_mrm,
         DATE_FORMAT(DATE_ADD('month', -2,
                     DATE_PARSE(CAST(codmes AS VARCHAR), '%Y%m')), '%Y%m')        AS codmes_cs,
         CAST(cod_tip_doc AS VARCHAR)                                             AS tip_doc,
         CAST(CAST(cod_tip_doc AS INTEGER) AS VARCHAR)                            AS tip_doc_norm,
         CAST(key_value AS VARCHAR)                                               AS key_value,
         CAST(pd_comppp_reen_itc AS DOUBLE)                                       AS probabilidad,
         CAST(score_comppp_reen_itc AS BIGINT)                                    AS puntuacion,
         GREATEST(LEAST(CAST(pd_comppp_reen_itc AS DOUBLE), 1.0 - 1e-9), 1e-9)    AS p
    FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov5
   WHERE pd_comppp_reen_itc IS NOT NULL),
base AS (
  SELECT v.codmes,
         v.tip_doc,
         v.key_value,
         v.probabilidad,
         v.puntuacion,
         v.p,
         f.f_t,
         CASE WHEN COALESCE(c.dep_validado, 0) = 1 THEN 'DEPENDIENTE'
              WHEN COALESCE(c.mixto, 0)        = 1 THEN 'MIXTO'
              ELSE 'INDEPENDIENTE' END                                            AS trf_tipo_ingreso,
         CASE WHEN COALESCE(c.dep_validado, 0) = 1 THEN 'DEP'
              ELSE 'NO DEP' END                                                   AS trf_tipo_ingreso_dep,
         CASE WHEN s.id_value IS NULL              THEN 'SIN_DATO'
              WHEN COALESCE(s.flg_cs, 0) = 1       THEN 'CS'
              ELSE 'NO_CS' END                                                    AS trf_flg_cs_estado,
         CAST(CASE WHEN c.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER)          AS trf_falla_sin_tipo_ingreso,
         CAST(CASE WHEN s.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER)          AS trf_falla_sin_cta_sueldo
    FROM v5 v
    JOIN ft f
      ON f.codmes_mrm = v.codmes_mrm
    LEFT JOIN cls c
      ON c.id_value   = v.key_value
     AND c.tip_doc    = v.tip_doc
     AND c.codmes_mrm = v.codmes_mrm
    LEFT JOIN cs s
      ON s.id_value = v.key_value
     AND s.tip_doc  = v.tip_doc_norm
     AND s.codmes   = v.codmes_cs),
cal AS (
  SELECT b.*,
         GREATEST(LEAST(
           1.0 / (1.0 + exp(-(
             (CASE WHEN trf_tipo_ingreso_dep = 'DEP' THEN -1.4235902271832188
                                                     ELSE -1.8712301290911784 END)
           + (CASE WHEN trf_tipo_ingreso_dep = 'DEP' THEN  1.4307409240924087
                                                     ELSE  1.12194919105907   END) * ln(p)
           - (CASE WHEN trf_tipo_ingreso_dep = 'DEP' THEN  0.11673242216482149
                                                     ELSE  0.5587876581505312 END) * ln(1.0 - p)
           )))
         , 1.0 - 1e-9), 1e-9)                                                     AS pd_cal
    FROM base b),
pit AS (
  SELECT c.*,
         GREATEST(LEAST(
           normal_cdf(0.0, 1.0,
             ((inverse_normal_cdf(0.0, 1.0, pd_cal)
               + (CASE WHEN trf_tipo_ingreso_dep = 'DEP' THEN 0.061973725544583
                                                         ELSE 0.10257577255744288 END)
               + 0.034261721611022956)
              - sqrt(0.038030115964094044) * 1.0 * f_t)
             / sqrt(1.0 - 0.038030115964094044))
         , 1.0 - 1e-4), 1e-4)                                                     AS prob_modelo_cal
    FROM cal c)
SELECT codmes,
       tip_doc,
       key_value,
       probabilidad,
       puntuacion,
       trf_tipo_ingreso,
       trf_tipo_ingreso_dep,
       trf_flg_cs_estado,
       trf_falla_sin_tipo_ingreso,
       trf_falla_sin_cta_sueldo,
       f_t                                                                        AS trf_f_t,
       prob_modelo_cal,
       CAST(ROUND(1000.0 * (1.0 - prob_modelo_cal)) AS INTEGER)                   AS puntuacion_cal
  FROM pit
