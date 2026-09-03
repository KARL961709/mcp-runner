-- i00. Cobertura por codmes en ds_ec_cdd_cal: n, scoreo pd_raw, madurez 12m, IBK, RD12 (ibk maduro), pd_raw medio. Ventana + escalon + scoreo 100 pct.
SELECT CAST(codmes AS varchar) AS codmes,
       COUNT(*) AS n,
       SUM(flg_pd_raw) AS n_pdraw,
       SUM(CASE WHEN target_12m IS NOT NULL THEN 1 ELSE 0 END) AS n_mad12,
       SUM(flg_ibk) AS n_ibk,
       ROUND(AVG(CASE WHEN flg_ibk = 1 AND target_12m IS NOT NULL THEN CAST(target_12m AS double) END), 5) AS rd12_ibk,
       ROUND(AVG(pd_raw), 5) AS pd_raw_avg
FROM disc_model_owner.ds_ec_cdd_cal
GROUP BY CAST(codmes AS varchar)
ORDER BY 1
