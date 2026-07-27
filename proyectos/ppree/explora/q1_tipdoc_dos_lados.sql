-- ============================================================================
-- Q1. R8 - el formato de tip_doc medido en LOS DOS LADOS, que es lo que no hice.
--     v4 midio 69-79% del universo sin cruzar contra t_rsk_cta_sueldo, pero esa
--     tabla tiene ~5x mas filas por mes que la PO: no es cobertura, es el join.
--     Y en 40_drivers normalice tipdoc a entero de UN SOLO lado, lo que puede
--     romper cruces que antes funcionaban.
--     Devuelve el dominio literal de cada lado y la tasa de cruce con y sin
--     tip_doc, para separar el efecto del formato del efecto de la poblacion.
-- ============================================================================
WITH po AS (
  SELECT codmes_mrm, tip_doc, id_value
  FROM disc_model_owner.ds_stk_ree_pp_10_po
  WHERE codmes_mrm IN ('202312', '202406', '202506')
),
cs AS (
  SELECT CAST(codmes AS VARCHAR) AS codmes, CAST(key_value AS VARCHAR) AS id_value,
         CAST(tipdoc AS VARCHAR) AS tipdoc_crudo,
         CAST(CAST(tipdoc AS INTEGER) AS VARCHAR) AS tipdoc_int
  FROM e_perm_aws.t_rsk_cta_sueldo
  WHERE CAST(codmes AS VARCHAR) IN ('202311', '202405', '202505')
)
SELECT
  po.codmes_mrm,
  COUNT(*)                                                                        AS n_po,
  COUNT(DISTINCT po.tip_doc)                                                      AS n_dom_tipdoc_po,
  MIN(po.tip_doc)                                                                 AS tipdoc_po_min,
  MAX(po.tip_doc)                                                                 AS tipdoc_po_max,
  MIN(LENGTH(po.tip_doc))                                                         AS len_min_po,
  MAX(LENGTH(po.tip_doc))                                                         AS len_max_po,
  SUM(CASE WHEN a.id_value IS NOT NULL THEN 1 ELSE 0 END)                         AS n_cruza_solo_key,
  SUM(CASE WHEN b.id_value IS NOT NULL THEN 1 ELSE 0 END)                         AS n_cruza_key_tipdoc_crudo,
  SUM(CASE WHEN c.id_value IS NOT NULL THEN 1 ELSE 0 END)                         AS n_cruza_key_tipdoc_int
FROM po
LEFT JOIN (SELECT DISTINCT codmes, id_value FROM cs) a
       ON a.id_value = po.id_value
      AND a.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(po.codmes_mrm, '%Y%m')), '%Y%m')
LEFT JOIN (SELECT DISTINCT codmes, id_value, tipdoc_crudo FROM cs) b
       ON b.id_value = po.id_value AND b.tipdoc_crudo = po.tip_doc
      AND b.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(po.codmes_mrm, '%Y%m')), '%Y%m')
LEFT JOIN (SELECT DISTINCT codmes, id_value, tipdoc_int FROM cs) c
       ON c.id_value = po.id_value AND c.tipdoc_int = po.tip_doc
      AND c.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(po.codmes_mrm, '%Y%m')), '%Y%m')
GROUP BY 1
ORDER BY 1
