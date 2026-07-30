-- f07 VENTANA MEDIDA de ENR_STOCK_PP_FEM_3
SELECT codmes,
       count(*)                                           AS n_filas,
       count(DISTINCT id_value)                           AS n_cuentas,
       sum(CASE WHEN def12 IS NOT NULL THEN 1 ELSE 0 END) AS n_maduro,
       round(100.0 * avg(CAST(flg_cruce AS double)), 2)   AS pct_reniec
FROM disc_model_owner.enr_stock_pp_fem_3
GROUP BY codmes
ORDER BY codmes
