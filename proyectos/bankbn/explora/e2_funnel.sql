-- e2 FUNNEL: distribucion de flag_malo_12m (filtros de origen + target) + bad-rate
SELECT flag_malo_12m, COUNT(*) AS n, AVG(CAST(target_12m AS DOUBLE)) AS badrate_12m
FROM disc_model_owner.ds_adm_bpe_bankbn_drivers
GROUP BY flag_malo_12m
ORDER BY n DESC
