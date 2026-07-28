-- t10  match mes a mes: confirma cual columna gobernada es la serie que usa REE
-- Se piden los 24 meses 202401-202512 de las tres candidatas. La comparacion se
-- hace contra IPC_Lima_var_12m del parquet, cuyo contenido es variacion MENSUAL.
SELECT cod_mes,
       porc_ipc                AS cand_var_mensual,
       porc_ipc_var_porc_12m   AS cand_var_12m,
       mto_ipc_var_porc_mov    AS cand_var_mov,
       mto_ipc_base_2009100    AS cand_indice
FROM e_perm_aws.t_mst_bcrp_rsk
WHERE cod_mes >= '202401' AND cod_mes <= '202512'
ORDER BY cod_mes
