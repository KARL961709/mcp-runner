-- i02. Sub_producto en ds_ec_cdd_cal (post-filtro): n, IBK, scoreo, RD12 ibk maduro, pd_raw medio. Valida 2 (o mas) modelos.
SELECT sub_producto,
       COUNT(*) AS n,
       SUM(flg_ibk) AS n_ibk,
       SUM(flg_pd_raw) AS n_pdraw,
       SUM(CASE WHEN flg_ibk = 1 AND target_12m IS NOT NULL THEN 1 ELSE 0 END) AS n_ibk_mad12,
       ROUND(AVG(CASE WHEN flg_ibk = 1 AND target_12m IS NOT NULL THEN CAST(target_12m AS double) END), 5) AS rd12_ibk,
       ROUND(AVG(CASE WHEN flg_ibk = 1 THEN pd_raw END), 5) AS pd_raw_ibk
FROM disc_model_owner.ds_ec_cdd_cal
GROUP BY sub_producto
ORDER BY n DESC
