-- i07. Dominio COMPLETO de ca_tipo_prod (sub_producto) ANTES del filtro in (CDD,EC), sobre enr_ec_cdd (pre-filtro de 03). Detecta CDA u otros valores que 02/03 excluyen. Si enr_ec_cdd no existe, medir sobre los desembolsos _tmp.
SELECT sub_producto,
       COUNT(*) AS n,
       COUNT(DISTINCT CAST(codmes AS varchar)) AS n_meses,
       SUM(flg_pd_raw) AS n_pdraw,
       SUM(CASE WHEN cod_instit_financiera = '00002' THEN 1 ELSE 0 END) AS n_ibk
FROM disc_model_owner.enr_ec_cdd
GROUP BY sub_producto
ORDER BY n DESC
