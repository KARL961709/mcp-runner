-- w1 | Altas IBK en wrk_GDP_RCC_PPE por mes x subproducto. READ-ONLY.
--   codempresa 00002 = IBK. Confirma que trae P.FACIL en jun (y si hay jul),
--   volumen y codigos de subproducto para el cruce (key_value directo).
SELECT cast(codmes AS varchar) AS codmes,
       subproducto,
       count(*)                  AS n,
       count(DISTINCT key_value) AS n_cli
FROM e_perm_aws.wrk_GDP_RCC_PPE
WHERE codempresa = '00002'
  AND cast(codmes AS varchar) IN ('202605', '202606', '202607')
GROUP BY cast(codmes AS varchar), subproducto
ORDER BY 1, 2
