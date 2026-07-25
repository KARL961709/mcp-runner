-- VAL CAL: reconciliacion flg_clean + bad-rate
SELECT
    COUNT(*) AS n,
    SUM(CASE WHEN flg_clean=99 THEN 1 ELSE 0 END) AS n99,
    SUM(CASE WHEN flg_clean=98 THEN 1 ELSE 0 END) AS n98,
    SUM(CASE WHEN flg_clean=1  THEN 1 ELSE 0 END) AS n_clean,
    SUM(CASE WHEN flg_clean=0  THEN 1 ELSE 0 END) AS n_dirty,
    AVG(CASE WHEN flg_clean=1 THEN CAST(target_12m AS DOUBLE) END) AS badrate_clean_12m
FROM disc_model_owner.ds_adm_bpe_bankbn_cal
