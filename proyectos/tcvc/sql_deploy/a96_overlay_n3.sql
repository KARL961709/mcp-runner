-- a96. Valida overlay regimen NODO 3 dirty (flg_clean=0, IBK, maduro): post-202505 pd_cal debe quedar >= rd (conservador, no subestima); pre sin cambio.
SELECT CASE WHEN codmes >= '202505' THEN 'post' ELSE 'pre' END AS regimen, COUNT(*) AS n,
  ROUND(AVG(prob_modelo_cal), 5) AS pd_cal, ROUND(AVG(CAST(target_12m AS double)), 5) AS rd
FROM disc_model_owner.altas_adm_tcbank_cal
WHERE flg_ibk = 1 AND flg_clean = 0 AND nodo = 'NODO 3' AND codmes BETWEEN '202311' AND '202507' AND target_12m IS NOT NULL
GROUP BY CASE WHEN codmes >= '202505' THEN 'post' ELSE 'pre' END