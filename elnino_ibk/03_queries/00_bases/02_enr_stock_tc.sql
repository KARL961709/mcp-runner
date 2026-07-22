-- ============================================================
-- 02 · BASE Stock TC  ->  disc_model_owner.ENR_STOCK_TC_FEM_3
-- ============================================================
-- Grano: cuenta-mes de comportamiento TC, llevada a cliente (key_value) vía scr.
-- RETIENE TODAS LAS FILAS (incl. INSUFICIENTE/UNCASHED) para que la composición (%n)
--   refleje la cartera completa hasta el último mes cargado.
-- def12 = 1 si dsc_flg_malo_12m='MALO', 0 si 'BUENO', NULL en cualquier otro caso
--   (INSUF/UNCASHED/etc.) y NULL si codmes_mrm>'202504' (cohorte sin ventana 12m madura).
-- => RD usa def12 IS NOT NULL (cohorte cerrado, MALO/(BUENO+MALO));
--    Composición usa TODAS las filas (sin filtro).
-- Dedup de scr_comportc_rsk (GROUP BY) ANTES del join evita fan-out.
-- ============================================================
DROP TABLE IF EXISTS disc_model_owner.ENR_STOCK_TC_FEM_3;

CREATE TABLE disc_model_owner.ENR_STOCK_TC_FEM_3 AS
WITH BASE_0 AS (
  SELECT TAB.*, TAB2.key_value
  FROM e_perm_aws.ds_flg_comportc_rsk TAB
  LEFT JOIN (SELECT tip_doc, key_value, cod_cuc
             FROM e_perm_aws.scr_comportc_rsk WHERE TIP_DOC='1' GROUP BY 1,2,3) TAB2
    ON TAB.ID_VALUE = TAB2.cod_cuc
)
SELECT
  A.codmes_mrm AS codmes, A.key_value, A.ID_VALUE,
  CASE WHEN A.codmes_mrm > '202504' THEN NULL
       WHEN A.dsc_flg_malo_12m = 'MALO'  THEN 1
       WHEN A.dsc_flg_malo_12m = 'BUENO' THEN 0
       ELSE NULL END AS def12,
  B.cod_ubi_domicilio,
  TRIM(UPPER(B.dis_ubi_domicilio)) AS dis_ubi_domicilio,
  TRIM(UPPER(B.pro_ubi_domicilio)) AS pro_ubi_domicilio,
  TRIM(UPPER(B.dep_ubi_domicilio)) AS dep_ubi_domicilio,
  CASE WHEN B.key_value IS NOT NULL THEN 1 ELSE 0 END AS FLG_CRUCE
FROM BASE_0 A
LEFT JOIN e_perm_aws.t_mst_reniec_rsk B ON A.key_value = B.key_value AND B.TIP_DOC='1';
