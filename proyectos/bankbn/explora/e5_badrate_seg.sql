-- e5 BAD-RATE por segmento (solo poblacion evaluable BUENO/MALO)
SELECT flg_ppjj, COUNT(*) AS n,
    AVG(CAST(target_06m AS DOUBLE)) AS br_06m,
    AVG(CAST(target_12m AS DOUBLE)) AS br_12m
FROM disc_model_owner.ds_adm_bpe_bankbn_drivers
WHERE flag_malo_12m IN ('BUENO','MALO')
GROUP BY flg_ppjj
