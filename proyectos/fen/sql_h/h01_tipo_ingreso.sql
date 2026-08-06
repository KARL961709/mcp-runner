-- 01 valores reales de tipo_ingreso en el universo de RD historica
SELECT tipo_ingreso, count(*) AS n,
       min(codmes) AS desde, max(codmes) AS hasta
FROM disc_model_owner.pp_vc_ds_po_origpp
WHERE flg_calib_rd = 1
  AND CAST(codmes AS INTEGER) BETWEEN 201901 AND 202504
  AND subproducto_ = '5.P FACIL'
GROUP BY 1 ORDER BY 2 DESC
