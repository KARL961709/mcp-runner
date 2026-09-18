-- diag_stock_3_periodos | temporalidad del stock: rango de codmes y numero de particiones. Agregado, no data.
SELECT COUNT(DISTINCT codmes) AS n_codmes, MIN(codmes) AS cm_min, MAX(codmes) AS cm_max, COUNT(DISTINCT p_fecinformacion) AS n_part FROM e_perm_aws.scr_cmpbpeibk2_rsk
