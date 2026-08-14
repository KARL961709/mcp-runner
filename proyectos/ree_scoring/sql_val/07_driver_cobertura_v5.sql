-- 07. COBERTURA Y COMPOSICION DEL DRIVER SOBRE LA v5
--   tipo_ingreso se ancla en periodo = codmes - 1 por calendario, que es el ancla
--   de 40_drivers y no la del scorer anterior, que leia el driver un mes corrido.
--   Solo importa si la fila es DEPENDIENTE de fuente no inferida: todo lo demas
--   cae a NO DEP, igual que el COALESCE del ausente.
--   H66: SUSALUD entra en 202604 e INFERIDO_IND_MVP en 202605, dentro de esta
--   ventana y los dos hacia la rama que NO es DEP. Un salto de pct_dep ahi es
--   disponibilidad de fuente, no cliente.
WITH cls AS (
  SELECT id_value, tip_doc, codmes, tipo_ingreso
    FROM (SELECT SUBSTR(a.subject_id, 3)                                          AS id_value,
                 CAST(a.tip_doc AS VARCHAR)                                       AS tip_doc,
                 CAST(a.periodo AS VARCHAR)                                       AS codmes,
                 CASE WHEN a.sit_lab = 'DEPENDIENTE'
                       AND a.fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP')
                      THEN 'DEPENDIENTE' ELSE 'OTRO' END                          AS tipo_ingreso,
                 ROW_NUMBER() OVER (PARTITION BY SUBSTR(a.subject_id, 3), a.periodo,
                                                 CAST(a.tip_doc AS VARCHAR)
                                    ORDER BY a.p_fecinformacion DESC,
                                             a.subject_id ASC)                    AS rn
            FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir a
           WHERE CAST(a.numcarga AS INT) = 1
             AND CAST(a.periodo AS VARCHAR) >= '202312') r
   WHERE rn = 1),
v5 AS (
  SELECT CAST(codmes AS VARCHAR)                                                  AS codmes,
         DATE_FORMAT(DATE_ADD('month', -1,
                     DATE_PARSE(CAST(codmes AS VARCHAR), '%Y%m')), '%Y%m')        AS codmes_mrm,
         CAST(key_value AS VARCHAR)                                               AS id_value,
         CAST(cod_tip_doc AS VARCHAR)                                             AS tip_doc
    FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov5
   WHERE pd_comppp_reen_itc IS NOT NULL)
SELECT v.codmes,
       v.codmes_mrm,
       COUNT(*)                                                                   AS n,
       SUM(CASE WHEN c.id_value IS NULL THEN 1 ELSE 0 END)                        AS n_sin_driver,
       SUM(CASE WHEN c.tipo_ingreso = 'DEPENDIENTE' THEN 1 ELSE 0 END)            AS n_dep,
       100.0 * SUM(CASE WHEN c.tipo_ingreso = 'DEPENDIENTE' THEN 1 ELSE 0 END)
             / COUNT(*)                                                           AS pct_dep
  FROM v5 v
  LEFT JOIN cls c
    ON c.id_value = v.id_value
   AND c.tip_doc  = v.tip_doc
   AND c.codmes   = v.codmes_mrm
 GROUP BY 1, 2
 ORDER BY 1
