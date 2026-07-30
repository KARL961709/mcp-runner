-- f09 VENTANA MEDIDA de ENR_VC_FEM_3 (altas / originaciones) por anio y producto
SELECT substr(CAST(codmes AS varchar), 1, 4) AS anio,
       tipo_producto,
       count(*)                                                AS n_filas,
       sum(CASE WHEN def12_tc  IS NOT NULL THEN 1 ELSE 0 END)  AS n_mad_tc,
       sum(CASE WHEN def12_pp  IS NOT NULL THEN 1 ELSE 0 END)  AS n_mad_pp,
       sum(CASE WHEN def12_vc_ IS NOT NULL THEN 1 ELSE 0 END)  AS n_mad_vc,
       round(100.0 * avg(CAST(flg_cruce AS double)), 2)        AS pct_reniec
FROM disc_model_owner.enr_vc_fem_3
GROUP BY 1, 2
ORDER BY 1, 2
