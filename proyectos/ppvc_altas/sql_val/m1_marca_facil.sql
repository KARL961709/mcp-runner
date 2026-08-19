-- m1 | Valores de marca x marca_est DENTRO de '5.P FACIL' (jun/jul). READ-ONLY.
--   Objetivo: ver si ahi aparecen 'Swap' / 'CIMA' / algo != 'Regular' que haya que excluir.
--   Si todo es 'Regular', el filtro sub_prod ya basta; si no, ajusto f3.
SELECT marca, marca_est, count(*) AS n, count(DISTINCT ca_cod_unic) AS n_cli
FROM d_perm_aws.t_dsmb_pp_7339
WHERE ca_periodo IN ('202606', '202607') AND sub_prod = '5.P FACIL'
GROUP BY marca, marca_est
ORDER BY 3 DESC
