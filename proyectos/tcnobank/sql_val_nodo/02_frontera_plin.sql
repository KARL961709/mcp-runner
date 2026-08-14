-- 02_frontera_plin.sql | frontera de publicacion de PLIN, insumo de flg_plinero_u3m y de f1/f2. El build ancla en [M-3, M-1]. Interesa tanto el mes mas reciente publicado como el arranque: en el maestro PLIN no existe antes de 202302 y madura hasta ~202306, y hay que saber si eso es arranque de fuente o del agregado
SELECT CAST(p_codmes AS VARCHAR)                                                    AS codmes,
       count(*)                                                                     AS n_filas,
       count(DISTINCT cif_key)                                                      AS n_clientes,
       sum(CASE WHEN tipo_transf = 'Enviadas' THEN 1 ELSE 0 END)                    AS n_filas_enviadas,
       sum(CASE WHEN TRY_CAST(numero_trx AS DOUBLE) IS NULL THEN 1 ELSE 0 END)      AS n_trx_no_castea,
       round(sum(coalesce(TRY_CAST(numero_trx AS DOUBLE), 0)), 0)                   AS n_trx_total
FROM e_perm_aws.t_agg_retail_user_trx_plin
GROUP BY CAST(p_codmes AS VARCHAR)
ORDER BY 1
