-- b97. Calce SS.FF (flg_ibk=0): PD calibrada IBK-anclada vs RD, por clean/dirty, maduro 202311-202507.
SELECT flg_clean, COUNT(*) AS n, ROUND(AVG(prob_modelo_cal), 5) AS pd_cal, ROUND(AVG(CAST(target_12m AS double)), 5) AS rd, ROUND(100.0 * (AVG(prob_modelo_cal) / AVG(CAST(target_12m AS double)) - 1), 1) AS ec_pct
FROM disc_model_owner.altas_adm_tcbank_cal
WHERE flg_ibk = 0 AND codmes BETWEEN '202311' AND '202507' AND target_12m IS NOT NULL AND pd_raw IS NOT NULL
GROUP BY flg_clean