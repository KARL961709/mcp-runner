-- ============================================================================
-- 30a. VENTANA FUTURA k = 1..6 - mora, refi y castigo por mes relativo
--   Expande la PO con UNNEST y joinea por IGUALDAD de mes: un range join sobre
--   90 meses no entra. Partido en dos tablas (Lente 5); 30b hace k = 7..12.
--   El +k aca es legitimo: alimenta el TARGET, no un filtro (Lente 4).
-- ============================================================================
CREATE TABLE disc_model_owner.ds_stk_ree_pp_30_fut_a AS
WITH exp AS (
  SELECT
    po.codmes_mrm,
    po.tip_doc,
    po.id_value,
    k,
    DATE_FORMAT(DATE_ADD('month', k, DATE_PARSE(po.codmes_mrm, '%Y%m')), '%Y%m') AS codmes_fut
  FROM disc_model_owner.ds_stk_ree_pp_10_po po
  CROSS JOIN UNNEST(ARRAY[1, 2, 3, 4, 5, 6]) AS t (k)
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
  MAX(CASE WHEN k = 1 THEN dm_k END) AS dm_m1,
  MAX(CASE WHEN k = 2 THEN dm_k END) AS dm_m2,
  MAX(CASE WHEN k = 3 THEN dm_k END) AS dm_m3,
  MAX(CASE WHEN k = 4 THEN dm_k END) AS dm_m4,
  MAX(CASE WHEN k = 5 THEN dm_k END) AS dm_m5,
  MAX(CASE WHEN k = 6 THEN dm_k END) AS dm_m6,
  MAX(CASE WHEN k = 1 THEN missing_k END) AS miss_m1,
  MAX(CASE WHEN k = 2 THEN missing_k END) AS miss_m2,
  MAX(CASE WHEN k = 3 THEN missing_k END) AS miss_m3,
  MAX(CASE WHEN k = 4 THEN missing_k END) AS miss_m4,
  MAX(CASE WHEN k = 5 THEN missing_k END) AS miss_m5,
  MAX(CASE WHEN k = 6 THEN missing_k END) AS miss_m6,
  MAX(CASE WHEN k <= 3 THEN refi_k ELSE 0 END) AS refi_03m,
  MAX(refi_k)                                  AS refi_06m,
  MAX(CASE WHEN k <= 3 THEN cast_k ELSE 0 END) AS cast_03m,
  MAX(cast_k)                                  AS cast_06m
FROM j
GROUP BY 1, 2, 3
