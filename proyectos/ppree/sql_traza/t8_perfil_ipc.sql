-- t8  perfil de valores de las columnas candidatas de IPC en la tabla gobernada
-- Criterio de lectura: variacion MENSUAL ~ 0.3 (o 0.003 si viene en tanto por uno);
-- variacion 12m ~ 2 a 8; indice base 2009=100 ~ 100 a 250. La magnitud identifica que mide cada una.
SELECT 'mto_ipc_var_porc_mov' AS columna, COUNT(*) AS n, COUNT(mto_ipc_var_porc_mov) AS n_no_nulo,
       MIN(mto_ipc_var_porc_mov) AS v_min, AVG(mto_ipc_var_porc_mov) AS v_prom, MAX(mto_ipc_var_porc_mov) AS v_max
FROM e_perm_aws.t_mst_bcrp_rsk
UNION ALL
SELECT 'porc_ipc_var_porc_12m', COUNT(*), COUNT(porc_ipc_var_porc_12m),
       MIN(porc_ipc_var_porc_12m), AVG(porc_ipc_var_porc_12m), MAX(porc_ipc_var_porc_12m)
FROM e_perm_aws.t_mst_bcrp_rsk
UNION ALL
SELECT 'porc_ipc', COUNT(*), COUNT(porc_ipc), MIN(porc_ipc), AVG(porc_ipc), MAX(porc_ipc)
FROM e_perm_aws.t_mst_bcrp_rsk
UNION ALL
SELECT 'mto_ipc', COUNT(*), COUNT(mto_ipc), MIN(mto_ipc), AVG(mto_ipc), MAX(mto_ipc)
FROM e_perm_aws.t_mst_bcrp_rsk
UNION ALL
SELECT 'mto_ipc_base_2009100', COUNT(*), COUNT(mto_ipc_base_2009100),
       MIN(mto_ipc_base_2009100), AVG(mto_ipc_base_2009100), MAX(mto_ipc_base_2009100)
FROM e_perm_aws.t_mst_bcrp_rsk
UNION ALL
SELECT 'mto_idx_precios_ipc', COUNT(*), COUNT(mto_idx_precios_ipc),
       MIN(mto_idx_precios_ipc), AVG(mto_idx_precios_ipc), MAX(mto_idx_precios_ipc)
FROM e_perm_aws.t_mst_bcrp_rsk
UNION ALL
SELECT 'porc_ipc_no_transables', COUNT(*), COUNT(porc_ipc_no_transables),
       MIN(porc_ipc_no_transables), AVG(porc_ipc_no_transables), MAX(porc_ipc_no_transables)
FROM e_perm_aws.t_mst_bcrp_rsk
UNION ALL
SELECT 'mto_ipc_no_transables', COUNT(*), COUNT(mto_ipc_no_transables),
       MIN(mto_ipc_no_transables), AVG(mto_ipc_no_transables), MAX(mto_ipc_no_transables)
FROM e_perm_aws.t_mst_bcrp_rsk
UNION ALL
SELECT 'mto_metropolitana_lima', COUNT(*), COUNT(mto_metropolitana_lima),
       MIN(mto_metropolitana_lima), AVG(mto_metropolitana_lima), MAX(mto_metropolitana_lima)
FROM e_perm_aws.t_mst_bcrp_rsk
UNION ALL
SELECT 'mto_lima', COUNT(*), COUNT(mto_lima), MIN(mto_lima), AVG(mto_lima), MAX(mto_lima)
FROM e_perm_aws.t_mst_bcrp_rsk
ORDER BY 1
