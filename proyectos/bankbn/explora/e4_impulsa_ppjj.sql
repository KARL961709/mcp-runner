-- e4 IMPULSA / PPJJ
SELECT COUNT(*) AS n,
    SUM(flg_impulsa)      AS n_impulsa_m0,
    SUM(flg_impulsa_u12m) AS n_impulsa_u12m,
    SUM(flg_ppjj)         AS n_ppjj
FROM disc_model_owner.ds_adm_bpe_bankbn_drivers
