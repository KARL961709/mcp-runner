-- i08. Riesgo de CDA vs CDD vs EC (scored, IBK) sobre enr_ec_cdd (incluye CDA). Decide si CDA se agrupa con CDD o va como 3er modelo. enr_ec_cdd no tiene tipo_ingreso ni nodo, asi que es overall por sub_producto.
SELECT sub_producto,
       COUNT(*) AS n,
       SUM(flg_pd_raw) AS n_pdraw,
       SUM(CASE WHEN flg_pd_raw = 1 AND target_12m IS NOT NULL THEN 1 ELSE 0 END) AS n_scored_mad12,
       ROUND(AVG(CASE WHEN flg_pd_raw = 1 AND target_12m IS NOT NULL THEN CAST(target_12m AS double) END), 5) AS rd12_scored,
       ROUND(AVG(CASE WHEN flg_pd_raw = 1 THEN pd_raw END), 5) AS pd_raw_scored
FROM disc_model_owner.enr_ec_cdd
WHERE cod_instit_financiera = '00002'
GROUP BY sub_producto
ORDER BY n DESC
