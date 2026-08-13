-- ============================================================================
-- V4. PLIN - LOS LITERALES DE LA RECETA CONTRA EL DOMINIO REAL
--   scan: e_perm_aws.t_agg_retail_user_trx_plin en 202412
--   ancla: R8. La receta compara banco y tipo_transf contra listas de literales. Un
--          literal que no matchea no da error: da cero, y la variable queda apagada
--          en silencio. Se copian del dominio medido, no del texto del recibido
-- ============================================================================
SELECT 'tipo_transf'                                                                    AS campo,
       tipo_transf                                                                      AS valor,
       count(*)                                                                         AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 3)                               AS pct
FROM e_perm_aws.t_agg_retail_user_trx_plin
WHERE p_codmes = '202412'
GROUP BY tipo_transf
UNION ALL
SELECT 'banco', banco, count(*), round(100.0 * count(*) / sum(count(*)) OVER (), 3)
FROM e_perm_aws.t_agg_retail_user_trx_plin
WHERE p_codmes = '202412'
GROUP BY banco
ORDER BY campo, n DESC
LIMIT 40
