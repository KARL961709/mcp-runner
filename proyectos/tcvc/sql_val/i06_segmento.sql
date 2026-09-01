-- i06. pd_raw vs RD por eje (nodo y tipo_ingreso por separado) sobre ibk clean maduro -> gap por eje.
SELECT 'nodo' AS eje, CAST(nodo AS varchar) AS val, COUNT(*) AS n,
  ROUND(AVG(pd_raw), 5) AS pd, ROUND(AVG(CAST(target_12m AS double)), 5) AS rd
FROM disc_model_owner.ds_adm_tcbank_cal
WHERE flg_ibk = 1 AND flg_clean = 1 AND target_12m IS NOT NULL
GROUP BY nodo
UNION ALL
SELECT 'tping' AS eje, CAST(tipo_ingreso AS varchar) AS val, COUNT(*) AS n,
  ROUND(AVG(pd_raw), 5) AS pd, ROUND(AVG(CAST(target_12m AS double)), 5) AS rd
FROM disc_model_owner.ds_adm_tcbank_cal
WHERE flg_ibk = 1 AND flg_clean = 1 AND target_12m IS NOT NULL
GROUP BY tipo_ingreso
ORDER BY eje, val