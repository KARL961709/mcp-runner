-- e8 REACTIVA: distribucion del segmento (reactiva puro = exclusion CASO 3)
SELECT segmento_reactiva, COUNT(*) AS n,
       AVG(CAST(target_12m AS DOUBLE)) AS badrate_12m
FROM disc_model_owner.ds_adm_bpe_bankbn_drivers
GROUP BY segmento_reactiva
ORDER BY n DESC
