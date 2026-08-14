-- 01_frontera_360.sql | frontera de publicacion del 360, insumo del flag de pasivos del nodo. El build ancla en [M-6, M-1]: si la particion mas reciente no llega hasta el mes anterior al corte de decision, ese ancla es look-ahead en produccion aunque no lo sea en el build historico
SELECT CAST(codmes AS VARCHAR)                                                      AS codmes,
       count(*)                                                                     AS n_filas,
       count(DISTINCT key_value)                                                    AS n_clientes,
       sum(CASE WHEN TRY_CAST(saldo_fdp_tot_pasivo AS DOUBLE) IS NOT NULL
                THEN 1 ELSE 0 END)                                                  AS n_con_saldo_pasivo,
       sum(CASE WHEN TRY_CAST(saldo_fdp_tot_cts AS DOUBLE) IS NOT NULL
                THEN 1 ELSE 0 END)                                                  AS n_con_saldo_cts
FROM e_perm_aws.t_aws_360_cliente_mes_d3
WHERE CAST(codmes AS VARCHAR) >= '202501'
GROUP BY CAST(codmes AS VARCHAR)
ORDER BY 1
