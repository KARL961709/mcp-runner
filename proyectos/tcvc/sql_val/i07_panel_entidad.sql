-- i07. Panel para el ciclo: tamano y RD por entidad (clean maduro, todas las entidades).
SELECT cod_instit_financiera, COUNT(*) AS n,
  SUM(CASE WHEN flg_clean = 1 AND target_12m IS NOT NULL THEN 1 ELSE 0 END) AS n_clean_mat,
  ROUND(AVG(CASE WHEN flg_clean = 1 AND target_12m IS NOT NULL THEN CAST(target_12m AS double) END), 5) AS rd
FROM disc_model_owner.ds_adm_tcbank_cal
GROUP BY cod_instit_financiera
ORDER BY n DESC