-- ============================================================================
-- v39. EN QUE MES SE LEEN LOS DRIVERS. codmes o codmes-1
--
--   El CTAS 20_score_v1v2_final lee tipo_ingreso en codmes_drv = codmes, porque
--   el master 2609 cruza la pd mes con mes. El SQL anterior lo leia en codmes-1.
--   La verificacion del generador NO prueba esto: reconstruye la PD usando el
--   tipo_ingreso_dep que ya trae el master, asi que el mes del driver nunca entra.
--
--   VEREDICTO: si pct_igual_en_codmes > pct_igual_en_codmes_m1, el CTAS esta
--   bien. Si es al reves, hay que volver codmes_drv a codmes-1 en
--   30_genera_sql_final.py y regenerar -- NO editar el .sql a mano.
--
--   SEGUNDA VERSION: la primera murio con "exhausted resources". El defecto era
--   mio: para leer dos meses saque el INNER JOIN contra el perimetro y la
--   subconsulta barrio ds_rtd_rskvol_cas_ingr_ir entera con un ROW_NUMBER encima.
--   Aca cada fila del perimetro se desdobla en sus DOS meses objetivo con UNNEST,
--   y el driver entra por INNER JOIN contra ese conjunto -- un solo paso, el
--   mismo patron que ya corre en el CTAS.
--   Ademas la ventana baja a 7 meses de control en vez de 21: para decidir cual
--   de los dos anclajes reproduce no hace falta el panel completo.
--
--   La cascada de tipo_ingreso va literal del CTAS, con numcarga = 1 y el
--   desempate por p_fecinformacion: parafrasearla seria medir otra cosa.
-- ============================================================================
WITH po AS (
  SELECT CAST(codmes_mrm AS VARCHAR)                AS codmes,
         CAST(tip_doc AS VARCHAR)                   AS tip_doc,
         CAST(id_value AS VARCHAR)                  AS id_value,
         CAST(tipo_ingreso_dep AS VARCHAR)          AS celda_master,
         CAST(falla_sin_tipo_ingreso AS INTEGER)    AS falla_sin_ti
  FROM disc_model_owner.ds_stk_ree_pp_cal
  WHERE flg_scope_ree = 1
    AND codmes_mrm IN ('202403', '202406', '202409', '202412', '202503', '202506', '202509')
),
obj AS (
  SELECT p.codmes,
         p.tip_doc,
         p.id_value,
         p.celda_master,
         p.falla_sin_ti,
         t.etq,
         CASE WHEN t.etq = 'codmes' THEN p.codmes
              ELSE DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(p.codmes, '%Y%m')), '%Y%m')
         END AS mes_driver
  FROM po p
  CROSS JOIN UNNEST(ARRAY['codmes', 'codmes_m1']) AS t(etq)
),
drv AS (
  SELECT codmes, tip_doc, id_value, tipo_ingreso
  FROM (
    SELECT CAST(a.periodo AS VARCHAR) AS codmes,
           CAST(a.tip_doc AS VARCHAR) AS tip_doc,
           SUBSTR(a.subject_id, 3)    AS id_value,
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
    INNER JOIN obj o
       ON CAST(a.periodo AS VARCHAR) = o.mes_driver
      AND SUBSTR(a.subject_id, 3)    = o.id_value
      AND CAST(a.tip_doc AS VARCHAR) = o.tip_doc
    WHERE CAST(a.numcarga AS INT) = 1
  ) r
  WHERE rn = 1
),
cmp AS (
  SELECT o.codmes,
         o.etq,
         o.celda_master,
         o.falla_sin_ti,
         d.tipo_ingreso,
         CASE WHEN d.id_value IS NULL THEN 0 ELSE 1 END AS cruza,
         CASE WHEN o.celda_master =
                   CASE WHEN d.tipo_ingreso = 'DEPENDIENTE' THEN 'DEP' ELSE 'NO DEP' END
              THEN 1 ELSE 0 END AS igual
  FROM obj o
  LEFT JOIN drv d
         ON d.codmes = o.mes_driver AND d.tip_doc = o.tip_doc AND d.id_value = o.id_value
)
SELECT codmes,
       SUM(CASE WHEN etq = 'codmes' THEN 1 ELSE 0 END)                                AS n,
       SUM(CASE WHEN etq = 'codmes' THEN falla_sin_ti ELSE 0 END)                     AS n_sin_tipo_ingreso,
       SUM(CASE WHEN etq = 'codmes' THEN cruza ELSE 0 END)                            AS n_cruza_codmes,
       SUM(CASE WHEN etq = 'codmes_m1' THEN cruza ELSE 0 END)                         AS n_cruza_codmes_m1,
       ROUND(100.0 * SUM(CASE WHEN etq = 'codmes' THEN igual ELSE 0 END)
             / NULLIF(SUM(CASE WHEN etq = 'codmes' THEN 1 ELSE 0 END), 0), 4)         AS pct_igual_en_codmes,
       ROUND(100.0 * SUM(CASE WHEN etq = 'codmes_m1' THEN igual ELSE 0 END)
             / NULLIF(SUM(CASE WHEN etq = 'codmes_m1' THEN 1 ELSE 0 END), 0), 4)      AS pct_igual_en_codmes_m1
FROM cmp
GROUP BY codmes
ORDER BY 1
