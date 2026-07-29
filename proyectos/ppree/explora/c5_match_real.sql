-- c5 | LA medicion que decide: que fraccion del stock cruza de verdad contra
--      cada driver, con el mismo join del paso 80. Ultimos meses
WITH d AS (
  SELECT CAST(codmes AS VARCHAR) AS codmes,
         DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(CAST(codmes AS VARCHAR), '%Y%m')), '%Y%m') AS codmes_mrm,
         CAST(cod_tip_doc AS VARCHAR) AS tip_doc,
         CAST(key_value AS VARCHAR)   AS id_value
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4
  WHERE CAST(codmes AS VARCHAR) >= '202604'
    AND pd_comppp_reen_itc IS NOT NULL
  GROUP BY 1, 2, 3, 4
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
    WHERE CAST(a.numcarga AS INT) = 1
      AND CAST(a.periodo AS VARCHAR) >= '202603'
  ) r
  WHERE rn = 1
),
cs AS (
  SELECT CAST(codmes AS VARCHAR)                  AS codmes,
         CAST(key_value AS VARCHAR)               AS id_value,
         CAST(CAST(tipdoc AS INTEGER) AS VARCHAR) AS tip_doc,
         MAX(CAST(flg_cs_riesgos AS INTEGER))     AS flg_cs
  FROM e_perm_aws.t_rsk_cta_sueldo
  WHERE CAST(codmes AS VARCHAR) >= '202602'
  GROUP BY 1, 2, 3
)
SELECT d.codmes,
       d.codmes_mrm,
       COUNT(*)                                                                        AS n_stock,
       ROUND(100.0 * AVG(CASE WHEN c.id_value IS NULL THEN 1.0 ELSE 0.0 END), 2)       AS pct_sin_tipo_ingreso,
       ROUND(100.0 * AVG(CASE WHEN s.id_value IS NULL THEN 1.0 ELSE 0.0 END), 2)       AS pct_sin_cta_sueldo,
       ROUND(100.0 * AVG(CASE WHEN c.tipo_ingreso = 'DEPENDIENTE' THEN 1.0 ELSE 0.0 END), 2) AS pct_dep_medido,
       ROUND(100.0 * AVG(CASE WHEN c.tipo_ingreso = 'MIXTO' THEN 1.0 ELSE 0.0 END), 2) AS pct_mixto,
       ROUND(100.0 * AVG(CASE WHEN COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') = 'DEPENDIENTE'
                              THEN 1.0 ELSE 0.0 END), 2)                               AS pct_dep_aplicado
FROM d
LEFT JOIN cls c ON c.id_value = d.id_value AND c.tip_doc = d.tip_doc AND c.codmes = d.codmes_mrm
LEFT JOIN cs  s ON s.id_value = d.id_value AND s.tip_doc = d.tip_doc
               AND s.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(d.codmes_mrm, '%Y%m')), '%Y%m')
GROUP BY d.codmes, d.codmes_mrm
ORDER BY 1 DESC
