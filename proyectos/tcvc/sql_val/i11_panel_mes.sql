-- i11. Panel entidad x mes (clean maduro): RD por cod_instit_financiera x codmes -> insumo del ciclo/rho.
SELECT cod_instit_financiera, codmes, COUNT(*) AS n, SUM(target_12m) AS malos,
  ROUND(AVG(CAST(target_12m AS double)), 6) AS rd
FROM disc_model_owner.ds_adm_tcbank_cal
WHERE flg_clean = 1 AND target_12m IS NOT NULL
GROUP BY cod_instit_financiera, codmes
ORDER BY cod_instit_financiera, codmes