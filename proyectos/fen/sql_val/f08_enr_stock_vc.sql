-- f08 VENTANA MEDIDA de ENR_STOCK_VC_FEM_3 (grano cliente, historia mas larga)
SELECT codmes,
       count(*)                                              AS n_filas,
       count(DISTINCT key_value)                             AS n_clientes,
       sum(CASE WHEN def12_vc IS NOT NULL THEN 1 ELSE 0 END) AS n_maduro,
       sum(CASE WHEN dep_ubi_domicilio IS NULL THEN 1 ELSE 0 END) AS n_sin_reniec
FROM disc_model_owner.enr_stock_vc_fem_3
GROUP BY codmes
ORDER BY codmes
