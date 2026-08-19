-- t3 | Frescura de t_dsmb_pp_7339 por periodo x sub_prod. READ-ONLY.
--   Confirma hasta que mes llega y si tiene 202606/202607.
SELECT ca_periodo, sub_prod, count(*) AS n, count(DISTINCT ca_cod_unic) AS n_cli
FROM d_perm_aws.t_dsmb_pp_7339
WHERE ca_periodo >= '202603'
GROUP BY ca_periodo, sub_prod
ORDER BY 1 DESC, 2
