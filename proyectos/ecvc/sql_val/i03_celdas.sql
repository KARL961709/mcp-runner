-- i03. Celdas sub_producto x tipo_ingreso x nodo (IBK maduro scoreado): n, malos, RD12, pd_raw medio. Viabilidad de celda + shrinkage del chico.
SELECT sub_producto, tipo_ingreso, nodo,
       COUNT(*) AS n,
       SUM(CASE WHEN target_12m = 1 THEN 1 ELSE 0 END) AS malos12,
       ROUND(AVG(CAST(target_12m AS double)), 5) AS rd12,
       ROUND(AVG(pd_raw), 5) AS pd_raw_avg
FROM disc_model_owner.ds_ec_cdd_cal
WHERE flg_ibk = 1 AND flg_pd_raw = 1 AND target_12m IS NOT NULL
GROUP BY sub_producto, tipo_ingreso, nodo
ORDER BY sub_producto, tipo_ingreso, nodo
