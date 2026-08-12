-- 41_lra_mensual.sql | serie mensual de la tasa de malos bajo las cuatro definiciones de target, con la pd cruda al lado, para fijar la LRA y ver cuanto sesga cada criterio
SELECT p_codmes,
       flg_maduro,
       count(*)                                                       AS n_est,
       round(100.0 * avg(CAST(obs_m12 AS DOUBLE)), 1)                 AS pct_obs_m12,
       count(target_12m)                                              AS n_t12,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 3)              AS rd_pub,
       round(100.0 * avg(CAST(target_12m_corr AS DOUBLE)), 3)         AS rd_corr,
       round(100.0 * avg(CAST(target_12m_b30 AS DOUBLE)), 3)          AS rd_b30,
       round(100.0 * avg(CAST(target_12m_full AS DOUBLE)), 3)         AS rd_full,
       round(100.0 * avg(pd_raw), 3)                                  AS pd_raw,
       round(100.0 * avg(pd_cal_pub), 3)                              AS pd_cal_pub
FROM disc_model_owner.ds_tcnobank_calib_v1
WHERE prelacion_00m = 1
GROUP BY p_codmes, flg_maduro
ORDER BY p_codmes
