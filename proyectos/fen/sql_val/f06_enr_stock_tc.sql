-- f06 VENTANA MEDIDA de ENR_STOCK_TC_FEM_3 (meses con filas, no min/max)
SELECT codmes,
       count(*)                                                   AS n_filas,
       count(DISTINCT key_value)                                  AS n_clientes,
       sum(CASE WHEN def12 IS NOT NULL THEN 1 ELSE 0 END)         AS n_maduro,
       round(100.0 * avg(CAST(flg_cruce AS double)), 2)           AS pct_reniec
FROM disc_model_owner.enr_stock_tc_fem_3
GROUP BY codmes
ORDER BY codmes
