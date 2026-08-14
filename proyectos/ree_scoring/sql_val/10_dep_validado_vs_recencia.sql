-- 10. DEP VALIDADO CONTRA LO QUE ELIGE EL DESEMPATE POR RECENCIA
--   la regla es quedarse solo con dependientes validados. El desempate vigente
--   ordena por p_fecinformacion DESC, o sea prefiere lo mas reciente antes que lo
--   validado: si una fuente inferida llega despues, pisa la clasificacion previa.
--   n_degradado es exactamente eso: el cliente TIENE registro dependiente validado
--   en el mes y aun asi no sale DEP. Si salta en 202605 el defecto esta confirmado
--   y medido. Si es plano, la caida de pct_dep es perdida real de validacion.
WITH r AS (
  SELECT CAST(a.periodo AS VARCHAR)                                               AS periodo,
         SUBSTR(a.subject_id, 3)                                                  AS id_value,
         CAST(a.tip_doc AS VARCHAR)                                               AS tip_doc,
         CASE WHEN a.sit_lab = 'DEPENDIENTE'
               AND a.fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP')
              THEN 1 ELSE 0 END                                                   AS dep_validado,
         ROW_NUMBER() OVER (PARTITION BY SUBSTR(a.subject_id, 3), a.periodo,
                                         CAST(a.tip_doc AS VARCHAR)
                            ORDER BY a.p_fecinformacion DESC,
                                     a.subject_id ASC)                            AS rn
    FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir a
   WHERE CAST(a.numcarga AS INT) = 1
     AND CAST(a.periodo AS VARCHAR) BETWEEN '202603' AND '202606'),
g AS (
  SELECT periodo,
         id_value,
         tip_doc,
         COUNT(*)                                                                 AS n_reg,
         MAX(dep_validado)                                                         AS tiene_validado,
         MAX(CASE WHEN rn = 1 THEN dep_validado END)                               AS elige_validado
    FROM r
   GROUP BY 1, 2, 3)
SELECT periodo,
       COUNT(*)                                                                   AS n_clientes,
       SUM(tiene_validado)                                                        AS n_con_dep_validado,
       SUM(elige_validado)                                                        AS n_sale_dep,
       SUM(CASE WHEN tiene_validado = 1 AND elige_validado = 0
                THEN 1 ELSE 0 END)                                                AS n_degradado,
       AVG(CAST(n_reg AS DOUBLE))                                                 AS reg_por_cliente,
       MAX(n_reg)                                                                 AS max_reg_cliente
  FROM g
 GROUP BY 1
 ORDER BY 1
