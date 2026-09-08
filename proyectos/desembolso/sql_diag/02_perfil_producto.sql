-- 02_perfil_producto.sql | top desc_producto de user_desembolso con clientes, monto y rango de meses, para identificar a que modelo mapea el producto y como se filtra la poblacion. READ-ONLY
SELECT desc_producto,
       count(*) AS n,
       count(distinct key_value) AS n_cli,
       round(sum(cast(mto_desembolso AS double)) / 1000000.0, 2) AS mto_mm,
       min(cast(cod_mes AS int)) AS cm_min,
       max(cast(cod_mes AS int)) AS cm_max
FROM d_perm_aws.user_desembolso
GROUP BY desc_producto
ORDER BY n_cli DESC
