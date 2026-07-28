-- t11  serie completa de porc_ipc sobre la ventana que usa el modelo macro
-- 201901-202506 (66 meses de fit, COVID incluido en el rango y excluido en el ajuste)
-- mas 202507-202604, que es donde f_t se aplica. Cierra la verificacion al 100 por ciento.
SELECT cod_mes, porc_ipc
FROM e_perm_aws.t_mst_bcrp_rsk
WHERE cod_mes >= '201801' AND cod_mes <= '202604'
ORDER BY cod_mes
