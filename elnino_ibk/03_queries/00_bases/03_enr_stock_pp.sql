-- ============================================================
-- 03 · BASE Stock PP  ->  disc_model_owner.ENR_STOCK_PP_FEM_3
-- ============================================================
-- Grano: cuenta-mes de comportamiento PP. id_value -> reniec.key_value directo.
-- RETIENE TODAS LAS FILAS (incl. INSUFICIENTE/etc.) para composición de cartera completa.
-- def12 = 1 si 'MALO', 0 si 'BUENO', NULL en otro caso; NULL si codmes_mrm>'202504'.
-- => RD usa def12 IS NOT NULL; Composición usa todas las filas. Historia 202201+.
-- ============================================================
DROP TABLE IF EXISTS disc_model_owner.ENR_STOCK_PP_FEM_3;

CREATE TABLE disc_model_owner.ENR_STOCK_PP_FEM_3 AS
SELECT
  A.codmes_mrm AS codmes, A.id_value,
  CASE WHEN A.codmes_mrm > '202504' THEN NULL
       WHEN A.dsc_flg_malo_12m = 'MALO'  THEN 1
       WHEN A.dsc_flg_malo_12m = 'BUENO' THEN 0
       ELSE NULL END AS def12,
  B.cod_ubi_domicilio,
  TRIM(UPPER(B.dis_ubi_domicilio)) AS dis_ubi_domicilio,
  TRIM(UPPER(B.pro_ubi_domicilio)) AS pro_ubi_domicilio,
  TRIM(UPPER(B.dep_ubi_domicilio)) AS dep_ubi_domicilio,
  CASE WHEN B.key_value IS NOT NULL THEN 1 ELSE 0 END AS FLG_CRUCE
FROM e_perm_aws.ds_flg_compppibk_rsk A
LEFT JOIN e_perm_aws.t_mst_reniec_rsk B ON A.id_value = B.key_value AND B.TIP_DOC='1'
WHERE A.tip_doc='1';
