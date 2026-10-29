-- ============================================================================
-- v39. EN QUE MES SE LEEN LOS DRIVERS. codmes o codmes-1
--
--   El CTAS 20_score_v1v2_final lee tipo_ingreso en codmes_drv = codmes, porque
--   el master 2609 cruza la pd mes con mes. El SQL anterior lo leia en codmes-1.
--   La verificacion del generador NO prueba esto: reconstruye la PD usando el
--   tipo_ingreso_dep que ya trae el master, asi que el mes del driver nunca entra.
--   Aca se prueba contra el dato.
--
--   Para cada fila del perimetro se deriva tipo_ingreso en los DOS meses y se
--   compara contra el tipo_ingreso_dep del master. El que reproduzca manda.
--
--   VEREDICTO: si pct_igual_en_codmes > pct_igual_en_codmes_m1, el CTAS esta
--   bien y se corre. Si es al reves, hay que volver codmes_drv a codmes-1 en
--   30_genera_sql_final.py y regenerar -- NO editar el .sql a mano.
--
--   La cascada de tipo_ingreso se copia literal del CTAS, incluido el filtro
--   numcarga = 1 y el desempate por p_fecinformacion: si se parafrasea, se mide
--   otra cosa.
-- ============================================================================
WITH po AS (
  SELECT CAST(codmes_mrm AS VARCHAR)  AS codmes,
         CAST(codmes_scr AS VARCHAR)  AS codmes_mas1,
         CAST(tip_doc AS VARCHAR)     AS tip_doc,
         CAST(id_value AS VARCHAR)    AS id_value,
         CAST(tipo_ingreso_dep AS VARCHAR) AS celda_master,
         CAST(falla_sin_tipo_ingreso AS INTEGER) AS falla_sin_ti
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE flg_scope_ree = 1
    AND codmes_mrm BETWEEN '202401' AND '202509'
),
drv AS (
  SELECT tip_doc, id_value, codmes, tipo_ingreso
  FROM (
    SELECT CAST(a.tip_doc AS VARCHAR) AS tip_doc,
           SUBSTR(a.subject_id, 3)    AS id_value,
           CAST(a.periodo AS VARCHAR) AS codmes,
           CASE
             WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente NOT IN ('INFERIDO', 'EXPERIAN', 'SUSALUD', 'INFERIDO_IND_MVP') THEN 'DEPENDIENTE'
             WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente IN ('INFERIDO', 'EXPERIAN', 'SUSALUD', 'INFERIDO_IND_MVP') THEN 'MIXTO'
             WHEN a.sit_lab = 'MIXTO' THEN 'MIXTO'
             ELSE 'INDEPENDIENTE'
           END AS tipo_ingreso,
           ROW_NUMBER() OVER (
             PARTITION BY SUBSTR(a.subject_id, 3), a.periodo, CAST(a.tip_doc AS VARCHAR)
             ORDER BY a.p_fecinformacion DESC, a.subject_id ASC) AS rn
    FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir a
    WHERE CAST(a.numcarga AS INT) = 1
      AND CAST(a.periodo AS VARCHAR) BETWEEN '202312' AND '202509'
  ) r
  WHERE rn = 1
),
m1 AS (
  SELECT CAST(codmes AS VARCHAR) AS codmes_origen,
         DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(CAST(codmes AS VARCHAR), '%Y%m')), '%Y%m') AS codmes_mas1,
         tip_doc, id_value, tipo_ingreso
  FROM drv
)
SELECT SUBSTR(p.codmes, 1, 4)                                                  AS anio,
       COUNT(*)                                                                AS n,
       SUM(CASE WHEN p.falla_sin_ti = 1 THEN 1 ELSE 0 END)                     AS n_sin_tipo_ingreso,
       SUM(CASE WHEN a.id_value IS NOT NULL THEN 1 ELSE 0 END)                 AS n_cruza_en_codmes,
       SUM(CASE WHEN b.id_value IS NOT NULL THEN 1 ELSE 0 END)                 AS n_cruza_en_codmes_m1,
       ROUND(100.0 * AVG(CASE WHEN p.celda_master =
              CASE WHEN a.tipo_ingreso = 'DEPENDIENTE' THEN 'DEP' ELSE 'NO DEP' END
            THEN 1.0 ELSE 0.0 END), 4)                                         AS pct_igual_en_codmes,
       ROUND(100.0 * AVG(CASE WHEN p.celda_master =
              CASE WHEN b.tipo_ingreso = 'DEPENDIENTE' THEN 'DEP' ELSE 'NO DEP' END
            THEN 1.0 ELSE 0.0 END), 4)                                         AS pct_igual_en_codmes_m1
FROM po p
LEFT JOIN drv a
       ON a.codmes = p.codmes AND a.tip_doc = p.tip_doc AND a.id_value = p.id_value
LEFT JOIN m1 b
       ON b.codmes_mas1 = p.codmes AND b.tip_doc = p.tip_doc AND b.id_value = p.id_value
GROUP BY SUBSTR(p.codmes, 1, 4)
ORDER BY 1
