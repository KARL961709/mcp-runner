-- diag_stock_2_size | grano/tamano del stock: filas y llaves distintas (key_value es la llave estandar en los _rsk). Agregado, no data.
SELECT COUNT(*) AS n_filas, COUNT(DISTINCT key_value) AS n_keys FROM e_perm_aws.scr_cmpbpeibk2_rsk
