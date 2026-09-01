-- i05. Viabilidad de celdas fit (ibk clean maduro): n, malos, RD, pd_raw por tipo_ingreso x nodo.
SELECT tipo_ingreso, nodo, COUNT(*) AS n, SUM(target_12m) AS malos,
  ROUND(AVG(CAST(target_12m AS double)), 5) AS rd,
  ROUND(AVG(pd_raw), 5) AS pd_raw
FROM disc_model_owner.ds_adm_tcbank_cal
WHERE flg_ibk = 1 AND flg_clean = 1 AND target_12m IS NOT NULL
GROUP BY tipo_ingreso, nodo
ORDER BY tipo_ingreso, nodo