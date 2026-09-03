-- i01. Entidades presentes (panel para ciclo/rho): n, meses distintos, IBK, RD12. Decide si hay SS.FF o EC es IBK-only.
SELECT cod_instit_financiera,
       MAX(flg_ibk) AS es_ibk,
       COUNT(*) AS n,
       COUNT(DISTINCT CAST(codmes AS varchar)) AS n_meses,
       SUM(CASE WHEN target_12m IS NOT NULL THEN 1 ELSE 0 END) AS n_mad12,
       ROUND(AVG(CASE WHEN target_12m IS NOT NULL THEN CAST(target_12m AS double) END), 5) AS rd12
FROM disc_model_owner.ds_ec_cdd_cal
GROUP BY cod_instit_financiera
ORDER BY n DESC
