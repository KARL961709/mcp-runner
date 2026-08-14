-- 03_frontera_cta_sueldo.sql | frontera de publicacion de cuenta sueldo, insumo de flg_cs_v2. Es el ancla mas ajustada del nodo: k=-1 exacto, sin ventana que amortigue. Si esta particion se publica tarde, el nodo no se puede calcular el mes de la decision
SELECT CAST(codmes AS VARCHAR)                                                      AS codmes,
       count(*)                                                                     AS n_filas,
       count(DISTINCT key_value)                                                    AS n_clientes,
       sum(CASE WHEN TRY_CAST(flg_cs_riesgos AS INTEGER) = 1 THEN 1 ELSE 0 END)     AS n_flg_uno,
       sum(CASE WHEN TRY_CAST(flg_cs_riesgos AS INTEGER) = 0 THEN 1 ELSE 0 END)     AS n_flg_cero,
       sum(CASE WHEN TRY_CAST(flg_cs_riesgos AS INTEGER) IS NULL THEN 1 ELSE 0 END) AS n_flg_nulo
FROM e_perm_aws.t_rsk_cta_sueldo
WHERE CAST(codmes AS VARCHAR) >= '202501'
GROUP BY CAST(codmes AS VARCHAR)
ORDER BY 1
