-- ============================================================
-- 04 · BASE Stock VC (venta cruzada)  ->  disc_model_owner.ENR_STOCK_VC_FEM_3
-- ============================================================
-- Grano: CLIENTE-mes (key_value). Combina stock TC + stock PP.
-- malo = MALO en TC o PP; evaluable = tiene BUENO/MALO en al menos un producto.
-- def12_vc = malo si evaluable; NULL si no evaluable o codmes>'202504'.
-- Historia: 202201+ (la más larga; meses tempranos son PP-dominantes, TC entra 202304/06).
-- ============================================================
DROP TABLE IF EXISTS disc_model_owner.ENR_STOCK_VC_FEM_3;

CREATE TABLE disc_model_owner.ENR_STOCK_VC_FEM_3 AS
WITH
tc AS (
  SELECT TAB.codmes_mrm AS codmes, TAB2.key_value AS key_value, TAB.dsc_flg_malo_12m AS flg
  FROM e_perm_aws.ds_flg_comportc_rsk TAB
  LEFT JOIN (SELECT key_value, cod_cuc FROM e_perm_aws.scr_comportc_rsk WHERE TIP_DOC='1' GROUP BY 1,2) TAB2
    ON TAB.ID_VALUE = TAB2.cod_cuc
),
pp AS (
  SELECT codmes_mrm AS codmes, id_value AS key_value, dsc_flg_malo_12m AS flg
  FROM e_perm_aws.ds_flg_compppibk_rsk WHERE tip_doc='1'
),
u AS (
  SELECT codmes, key_value, flg FROM tc
  UNION ALL
  SELECT codmes, key_value, flg FROM pp
),
cli AS (
  SELECT codmes, key_value,
    max(CASE WHEN flg='MALO' THEN 1 ELSE 0 END) AS malo,
    max(CASE WHEN flg IN ('BUENO','MALO') THEN 1 ELSE 0 END) AS evaluable
  FROM u WHERE key_value IS NOT NULL
  GROUP BY codmes, key_value
)
SELECT
  c.codmes, c.key_value,
  CASE WHEN c.codmes > '202504' THEN NULL
       WHEN c.evaluable = 0 THEN NULL
       ELSE c.malo END AS def12_vc,
  B.cod_ubi_domicilio,
  TRIM(UPPER(B.dis_ubi_domicilio)) AS dis_ubi_domicilio,
  TRIM(UPPER(B.pro_ubi_domicilio)) AS pro_ubi_domicilio,
  TRIM(UPPER(B.dep_ubi_domicilio)) AS dep_ubi_domicilio
FROM cli c
LEFT JOIN e_perm_aws.t_mst_reniec_rsk B ON c.key_value = B.key_value AND B.TIP_DOC='1';
