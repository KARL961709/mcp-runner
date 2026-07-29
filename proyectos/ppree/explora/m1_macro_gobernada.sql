-- m1  serie macro desde la TABLA GOBERNADA, no desde el parquet
-- porc_ipc = ticker PN01271PM = variacion porcentual MENSUAL del IPC de Lima.
-- Es la serie base sobre la que el pipeline calcula lag5 + media movil de 6.
-- Se piden tambien las dos vecinas como control de magnitud.
SELECT cod_mes,
       porc_ipc              AS ipc_var_mensual,
       porc_ipc_var_porc_12m AS ipc_var_12m,
       mto_ipc_base_2009100  AS ipc_indice
FROM e_perm_aws.t_mst_bcrp_rsk
WHERE cod_mes >= '201801' AND cod_mes <= '202607'
ORDER BY cod_mes
