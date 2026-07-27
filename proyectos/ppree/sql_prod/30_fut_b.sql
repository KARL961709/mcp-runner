-- ============================================================================
-- 30b. VENTANA FUTURA k = 7..12 - misma logica que 30a
--   refi_09m y cast_09m se completan en 70_cal combinando con 30a: aca solo
--   viven los meses 7..12, que es lo que esta tabla puede afirmar.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_30_fut_b AS
WITH exp AS (
  SELECT
    po.codmes_mrm,
    po.tip_doc,
    po.id_value,
    k,
    DATE_FORMAT(DATE_ADD('month', k, DATE_PARSE(po.codmes_mrm, '%Y%m')), '%Y%m') AS codmes_fut
  FROM disc_model_owner.ds_stk_ree_pp_10_po po
  CROSS JOIN UNNEST(ARRAY[7, 8, 9, 10, 11, 12]) AS t (k)
),
j AS (
  SELECT
    e.codmes_mrm, e.tip_doc, e.id_value, e.k,
    dm.dm_max                                                AS dm_k,
    CASE WHEN dm.codmes IS NULL THEN 1 ELSE 0 END            AS missing_k,
    CASE WHEN rf.flg_refi = 1 THEN 1 ELSE 0 END              AS refi_k,
    CASE WHEN cst.flg_castigo = 1 THEN 1 ELSE 0 END          AS cast_k
  FROM exp e
  LEFT JOIN disc_model_owner.ds_stk_ree_pp_20_dm dm
         ON dm.id_value = e.id_value AND dm.tip_doc = e.tip_doc AND dm.codmes = e.codmes_fut
  LEFT JOIN disc_model_owner.ds_stk_ree_pp_22_rf rf
         ON rf.id_value = e.id_value AND rf.tip_doc = e.tip_doc AND rf.codmes = e.codmes_fut
  LEFT JOIN disc_model_owner.ds_stk_ree_pp_23_cst cst
         ON cst.id_value = e.id_value AND cst.tip_doc = e.tip_doc AND cst.codmes = e.codmes_fut
)
SELECT
  codmes_mrm, tip_doc, id_value,
  MAX(CASE WHEN k =  7 THEN dm_k END) AS dm_m7,
  MAX(CASE WHEN k =  8 THEN dm_k END) AS dm_m8,
  MAX(CASE WHEN k =  9 THEN dm_k END) AS dm_m9,
  MAX(CASE WHEN k = 10 THEN dm_k END) AS dm_m10,
  MAX(CASE WHEN k = 11 THEN dm_k END) AS dm_m11,
  MAX(CASE WHEN k = 12 THEN dm_k END) AS dm_m12,
  MAX(CASE WHEN k =  7 THEN missing_k END) AS miss_m7,
  MAX(CASE WHEN k =  8 THEN missing_k END) AS miss_m8,
  MAX(CASE WHEN k =  9 THEN missing_k END) AS miss_m9,
  MAX(CASE WHEN k = 10 THEN missing_k END) AS miss_m10,
  MAX(CASE WHEN k = 11 THEN missing_k END) AS miss_m11,
  MAX(CASE WHEN k = 12 THEN missing_k END) AS miss_m12,
  MAX(CASE WHEN k <= 9 THEN refi_k ELSE 0 END) AS refi_07_09m,
  MAX(refi_k)                                  AS refi_07_12m,
  MAX(CASE WHEN k <= 9 THEN cast_k ELSE 0 END) AS cast_07_09m,
  MAX(cast_k)                                  AS cast_07_12m
FROM j
GROUP BY 1, 2, 3
