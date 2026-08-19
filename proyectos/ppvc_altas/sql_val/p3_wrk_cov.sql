-- p3 | Frescura de la otra fuente de altas del pipeline: RCC/GDP. READ-ONLY.
--   e_perm_aws.wrk_GDP_RCC_PPE (02_altas la usa). Si llega a jun/jul, sirve de fuente
--   de altas fresca (trae codmes, key_value, subproducto, codempresa, desembolso).
SELECT cast(codmes AS varchar)     AS codmes,
       count(*)                    AS n,
       count(DISTINCT key_value)   AS n_cli,
       count(DISTINCT codempresa)  AS n_emp
FROM e_perm_aws.wrk_GDP_RCC_PPE
GROUP BY cast(codmes AS varchar)
ORDER BY 1 DESC
LIMIT 12
