-- 13. LA CADENA FINAL CALCULADA EN SQL SOBRE LA v5, CONTRA LA SALIDA VIGENTE
--   es el nucleo del scorer corriendo en modo lectura: no crea ni toca nada.
--   El factor macro sale de la tabla gobernada, no de una tabla VALUES a mano.
--   Las constantes de centrado y capeo se congelan porque son de la calibracion:
--   recalcularlas contra el dato del mes dejaria el calendario a la deriva.
--   El ft se ancla en codmes_mrm = codmes - 1, que es el ancla de la calibracion.
--   dif_pp cerca de 0 significa que produccion ya corre con los coeficientes
--   finales. Una brecha sistematica significa que corre con los de v2.
WITH ipc AS (
  SELECT CAST(cod_mes AS VARCHAR)                                                 AS cm,
         CAST(porc_ipc AS DOUBLE)                                                 AS ipc
    FROM e_perm_aws.t_mst_bcrp_rsk),
mac AS (
  SELECT cm,
         AVG(ipc)  OVER (ORDER BY cm ROWS BETWEEN 10 PRECEDING AND 5 PRECEDING)   AS x,
         COUNT(*)  OVER (ORDER BY cm ROWS BETWEEN 10 PRECEDING AND 5 PRECEDING)   AS n_vent
    FROM ipc),
ft AS (
  SELECT cm                                                                       AS codmes_mrm,
         GREATEST(LEAST(
           (inverse_normal_cdf(0.0, 1.0, 0.04226346409008948)
             - sqrt(1.0 - 0.038030115964094044)
               * (-1.900195796163702 + 0.6583423568236846 * x))
           / sqrt(0.038030115964094044)
           + 0.19111262350586136
         , 0.7656842281878757), -1.1308495593693428)                              AS ft
    FROM mac
   WHERE n_vent = 6),
cls AS (
  SELECT SUBSTR(subject_id, 3)                                                    AS id_value,
         CAST(tip_doc AS VARCHAR)                                                 AS tip_doc,
         CAST(periodo AS VARCHAR)                                                 AS codmes_mrm,
         MAX(CASE WHEN sit_lab = 'DEPENDIENTE'
                   AND fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP')
                  THEN 1 ELSE 0 END)                                              AS dep_validado
    FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
   WHERE CAST(numcarga AS INT) = 1
     AND CAST(periodo AS VARCHAR) >= '202312'
   GROUP BY 1, 2, 3),
v5 AS (
  SELECT CAST(codmes AS VARCHAR)                                                  AS codmes,
         DATE_FORMAT(DATE_ADD('month', -1,
                     DATE_PARSE(CAST(codmes AS VARCHAR), '%Y%m')), '%Y%m')        AS codmes_mrm,
         CAST(key_value AS VARCHAR)                                               AS id_value,
         CAST(cod_tip_doc AS VARCHAR)                                             AS tip_doc,
         GREATEST(LEAST(CAST(pd_comppp_reen_itc AS DOUBLE), 1.0 - 1e-9), 1e-9)    AS p
    FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov5
   WHERE pd_comppp_reen_itc IS NOT NULL),
base AS (
  SELECT v.codmes,
         v.p,
         CASE WHEN COALESCE(c.dep_validado, 0) = 1 THEN 'DEP' ELSE 'NO DEP' END   AS seg,
         f.ft
    FROM v5 v
    LEFT JOIN cls c
      ON c.id_value   = v.id_value
     AND c.tip_doc    = v.tip_doc
     AND c.codmes_mrm = v.codmes_mrm
    JOIN ft f
      ON f.codmes_mrm = v.codmes_mrm),
cal AS (
  SELECT codmes, seg, ft,
         GREATEST(LEAST(
           1.0 / (1.0 + exp(-(
             (CASE WHEN seg = 'DEP' THEN -1.4235902271832188 ELSE -1.8712301290911784 END)
           + (CASE WHEN seg = 'DEP' THEN  1.4307409240924087 ELSE  1.12194919105907    END) * ln(p)
           - (CASE WHEN seg = 'DEP' THEN  0.11673242216482149 ELSE 0.5587876581505312  END) * ln(1.0 - p)
           )))
         , 1.0 - 1e-9), 1e-9)                                                     AS pd_cal
    FROM base),
pit AS (
  SELECT codmes, seg,
         GREATEST(LEAST(
           normal_cdf(0.0, 1.0,
             ((inverse_normal_cdf(0.0, 1.0, pd_cal)
               + (CASE WHEN seg = 'DEP' THEN 0.061973725544583 ELSE 0.10257577255744288 END)
               + 0.034261721611022956)
              - sqrt(0.038030115964094044) * 1.0 * ft)
             / sqrt(1.0 - 0.038030115964094044))
         , 1.0 - 1e-4), 1e-4)                                                     AS prob_modelo_cal
    FROM cal)
SELECT n.codmes,
       n.n,
       n.pct_dep,
       n.prob_nueva,
       v.prob_vigente,
       100.0 * (n.prob_nueva - v.prob_vigente)                                    AS dif_pp,
       n.punt_nueva,
       v.punt_vigente
  FROM (SELECT codmes,
               COUNT(*)                                                           AS n,
               100.0 * SUM(CASE WHEN seg = 'DEP' THEN 1 ELSE 0 END) / COUNT(*)    AS pct_dep,
               AVG(prob_modelo_cal)                                               AS prob_nueva,
               AVG(CAST(CAST(ROUND(1000.0 * (1.0 - prob_modelo_cal)) AS INTEGER) AS DOUBLE)) AS punt_nueva
          FROM pit
         GROUP BY 1) n
  LEFT JOIN (SELECT CAST(codmes AS VARCHAR)                                       AS codmes,
                    AVG(CAST(prob_modelo_cal AS DOUBLE))                          AS prob_vigente,
                    AVG(CAST(puntuacion_cal AS DOUBLE))                           AS punt_vigente
               FROM d_perm_aws.scr_stk_ree_pp_cal_202607
              GROUP BY 1) v
    ON v.codmes = n.codmes
 ORDER BY 1
