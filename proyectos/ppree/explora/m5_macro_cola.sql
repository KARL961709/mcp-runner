-- m5  cola de la serie macro gobernada
-- m1 llego hasta 202604. Para puntuar 202605-202607 hace falta f_t, y f_t
-- necesita el IPC de esos meses. Aqui se confirma si la gobernada ya los tiene.
SELECT cod_mes, porc_ipc AS ipc_var_mensual
FROM e_perm_aws.t_mst_bcrp_rsk
WHERE cod_mes >= '202601'
ORDER BY cod_mes
