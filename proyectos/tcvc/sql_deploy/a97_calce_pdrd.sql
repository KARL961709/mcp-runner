-- a97. Calce PD calibrada vs RD (target_12m) - clean IBK maduro 202311-202507. Debe reproducir el ancla.
SELECT COUNT(*) AS n, ROUND(AVG(prob_modelo_cal), 5) AS pd_cal, ROUND(AVG(CAST(target_12m AS double)), 5) AS rd
FROM disc_model_owner.altas_adm_tcbank_cal
WHERE flg_ibk = 1 AND flg_clean = 1 AND codmes BETWEEN '202311' AND '202507' AND target_12m IS NOT NULL